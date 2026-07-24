import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/services.dart';
import '../../theme/motion.dart';
import '../../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Color _backdrop = Color(0xFF003366);

  static const Duration _failSafeTimeout = Duration(seconds: 4);

  static const Duration _skipAffordanceDelay = Duration(milliseconds: 1200);

  VideoPlayerController? _controller;
  late final AnimationController _exit;

  Timer? _failSafe;
  Timer? _skipReveal;
  bool _showSkip = false;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _exit = AnimationController(vsync: this, duration: AppMotion.emphasized);

    unawaited(_startPlayback());

    _failSafe = Timer(_failSafeTimeout, () {
      if (!_videoReady) _finish();
    });
    _skipReveal = Timer(_skipAffordanceDelay, () {
      if (mounted) setState(() => _showSkip = true);
    });
  }

  Future<void> _startPlayback() async {
    final controller = VideoPlayerController.asset(
      'assets/animations/SplashScreen.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setVolume(0);
      await controller.setLooping(false);
      controller.addListener(_onTick);

      unawaited(WakelockPlus.enable());

      await controller.play();

      if (!mounted) return;
      setState(() => _videoReady = true);
      _failSafe?.cancel();
    } catch (error, stack) {
      debugPrint('SplashScreen: video playback unavailable — $error\n$stack');
      _finish();
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    if (value.isCompleted || value.position >= value.duration) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    _failSafe?.cancel();
    _skipReveal?.cancel();
    _controller?.removeListener(_onTick);

    if (!prefersReducedMotion(context)) {
      await _exit.forward();
    }
    if (!mounted) return;

    final auth = context.read<AuthService>();
    context.go(auth.isLoggedIn ? auth.getHomeRoute() : '/login');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _navigated) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(controller.play());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(controller.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _failSafe?.cancel();
    _skipReveal?.cancel();
    _controller?.removeListener(_onTick);

    unawaited(_controller?.dispose());
    unawaited(WakelockPlus.disable());
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: _backdrop,
      body: AnimatedBuilder(
        animation: _exit,
        builder: (context, child) {
          return Opacity(opacity: 1 - _exit.value, child: child);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _backdrop),

            if (_videoReady && controller != null)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),

            if (_showSkip && !_navigated)
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _SkipButton(onPressed: _finish),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: motionDuration(context, AppMotion.standard),
      curve: AppMotion.enter,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Semantics(
        button: true,
        label: 'تخطي مقدمة التطبيق',
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              child: Text(
                'تخطي',
                style: AppFonts.readex(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
