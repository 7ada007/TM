import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/services.dart';
import '../../theme/motion.dart';

/// Frame-based launch animation.
///
/// The four artwork frames in `assets/animations/` are cross-dissolved on a
/// single ticker. They are stacked bottom-to-top and only ever fade *in*: a
/// frame at full opacity covers the screen edge to edge (`BoxFit.cover`), so
/// everything beneath it is hidden without being faded out. That is what keeps
/// the sequence free of the opacity dip a symmetric cross-fade produces — at no
/// point is the composite less than fully opaque, so the backdrop can never
/// show through between frames.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Matches the artwork's own background (sampled from the frame corners) and
  /// the native launch screens, so the OS launch screen → Flutter hand-off is
  /// one continuous colour. Painted under the frames purely as insurance; the
  /// frames themselves cover it once decoded.
  static const Color _backdrop = Color(0xFF080808);

  static const List<String> _frames = [
    'assets/animations/screen1.png',
    'assets/animations/screen1-1.png',
    'assets/animations/screen1-2.png',
    'assets/animations/screen1-3.png',
  ];

  /// `_frames.length`, spelled out because the timings below are compile-time
  /// constants and a list length is not const-evaluable. Kept honest by the
  /// assertion in [initState].
  static const int _frameCount = 4;

  /// Gap between the start of one frame's entrance and the next.
  static const int _stepMs = 520;

  /// How long a frame takes to dissolve in over the one below it.
  static const int _dissolveMs = 340;

  /// Beat held on the final frame before handing over to the next route.
  static const int _finalHoldMs = 460;

  static const int _totalMs =
      _stepMs * (_frameCount - 1) + _dissolveMs + _finalHoldMs;

  /// Entrance scale for each frame — it settles *down* to 1.0 so the image is
  /// never smaller than the screen mid-transition.
  static const double _entranceScale = 0.05;

  /// Slow push across the whole sequence. Also always ≥ 1.0.
  static const double _driftScale = 0.035;

  /// Ceiling on how long decoding may hold the first frame back, and the
  /// backstop that guarantees we leave the splash even if something upstream
  /// never completes.
  static const Duration _decodeBudget = Duration(milliseconds: 700);
  static const Duration _failSafe = Duration(seconds: 5);

  late final AnimationController _controller;
  Timer? _failSafeTimer;
  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    assert(_frames.length == _frameCount);
    WidgetsBinding.instance.addObserver(this);

    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: _totalMs),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        });

    _failSafeTimer = Timer(_failSafe, _finish);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    // Decode every frame before the first one is shown. Four small PNGs cost a
    // few milliseconds, and paying it up front is what stops a later frame from
    // popping in a beat late while the raster thread decodes it mid-dissolve.
    // The budget means a slow or failed decode delays the animation rather than
    // blocking it — Image.asset would still load the frame lazily.
    try {
      await Future.wait([
        for (final frame in _frames) precacheImage(AssetImage(frame), context),
      ]).timeout(_decodeBudget);
    } catch (error) {
      debugPrint('SplashScreen: frame precache incomplete — $error');
    }

    if (!mounted || _navigated) return;

    if (prefersReducedMotion(context)) {
      // Settle straight onto the closing frame and hold it briefly.
      _controller.value = 1.0;
      await Future<void>.delayed(const Duration(milliseconds: _finalHoldMs));
      _finish();
      return;
    }

    await _controller.forward();
  }

  void _finish() {
    if (_navigated || !mounted) return;
    _navigated = true;

    _failSafeTimer?.cancel();

    // Handed over while the splash is still fully opaque. The route's
    // `splashHandoff` transition dissolves it out on exactly the curve that
    // fades `/login` in, so the two always sum to one opaque screen.
    final auth = context.read<AuthService>();
    context.go(auth.isLoggedIn ? auth.getHomeRoute() : '/login');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_navigated) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // Resume rather than restart: returning to a half-played splash should
        // finish it, not replay it.
        if (_started && !_controller.isAnimating && _controller.value < 1.0) {
          unawaited(_controller.forward());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _failSafeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Entrance progress of [index] at elapsed time [ms], eased.
  double _progress(int index, double ms) {
    final start = index * _stepMs;
    final raw = ((ms - start) / _dissolveMs).clamp(0.0, 1.0);
    return Curves.easeInOut.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The artwork is near-black in every frame, so the system icons have to
      // be light for the duration or they vanish into it.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _backdrop,
        // A stray tap should not be able to strand someone on the splash if a
        // frame ever fails to load, so the whole surface skips ahead.
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Semantics(
            label: 'مقدمة معهد طريق المجد',
            button: true,
            hint: 'اضغط لتخطي المقدمة',
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final ms = _controller.value * _totalMs;
                  final drift = 1.0 + _driftScale * _controller.value;

                  // Skip every frame the topmost opaque one already covers.
                  var first = 0;
                  for (var i = _frames.length - 1; i > 0; i--) {
                    if (_progress(i, ms) >= 1.0) {
                      first = i;
                      break;
                    }
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: _backdrop),
                      for (var i = first; i < _frames.length; i++)
                        _SplashFrame(
                          asset: _frames[i],
                          opacity: _progress(i, ms),
                          scale:
                              drift *
                              (1.0 +
                                  _entranceScale *
                                      (1.0 -
                                          Curves.easeOutCubic.transform(
                                            _progress(i, ms),
                                          ))),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashFrame extends StatelessWidget {
  const _SplashFrame({
    required this.asset,
    required this.opacity,
    required this.scale,
  });

  final String asset;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        // `cover` on a scale that is never below 1.0 means the frame fills the
        // screen on every aspect ratio, from a tall phone to a tablet, with no
        // letterboxing and no backdrop showing at the edges.
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          // Bilinear + mipmaps: the artwork is 440×957 and is upscaled on
          // nearly every device, so filtering is what keeps the gradients from
          // banding and the logo edges from aliasing.
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
