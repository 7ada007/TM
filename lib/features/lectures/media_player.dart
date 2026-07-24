import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/core.dart';
import '../../theme/motion.dart';
import '../../theme/theme.dart';

const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
const Duration _skip = Duration(seconds: 10);
const Duration _doubleTapSkip = Duration(seconds: 3);

class _QualityOption {
  final String label;
  final String url;

  const _QualityOption(this.label, this.url);
}

class _SeekFlash {
  final bool forward;
  final int id;

  const _SeekFlash(this.forward, this.id);
}

class PremiumVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String? posterPath;
  final ValueChanged<Duration>? onDurationResolved;
  final String? lectureId;
  final String lectureTitle;
  final String lectureSubject;

  const PremiumVideoPlayer({
    super.key,
    required this.videoPath,
    this.posterPath,
    this.onDurationResolved,
    this.lectureId,
    this.lectureTitle = '',
    this.lectureSubject = '',
  });

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  StreamInfo? _streamInfo;
  LectureWatchTracker? _tracker;

  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;

  final ValueNotifier<bool> _controlsVisible = ValueNotifier(true);
  final ValueNotifier<double> _speed = ValueNotifier(1.0);
  final ValueNotifier<BoxFit> _fit = ValueNotifier(BoxFit.contain);
  final ValueNotifier<bool> _buffering = ValueNotifier(false);
  final ValueNotifier<bool> _fullscreen = ValueNotifier(false);
  final ValueNotifier<String> _qualityLabel = ValueNotifier('تلقائي');
  final ValueNotifier<_SeekFlash?> _seekFlash = ValueNotifier(null);

  Timer? _hideTimer;
  Timer? _flashTimer;
  String? _activeUrl;
  Duration _resumeAt = Duration.zero;
  bool _resumePlaying = false;
  int _flashCounter = 0;
  bool _reachedEnd = false;

  VideoPlayerController? get controller => _controller;
  ValueListenable<bool> get controlsVisible => _controlsVisible;
  ValueListenable<double> get speed => _speed;
  ValueListenable<BoxFit> get fit => _fit;
  ValueListenable<bool> get buffering => _buffering;
  ValueListenable<String> get qualityLabel => _qualityLabel;
  ValueListenable<_SeekFlash?> get seekFlash => _seekFlash;
  bool get hasQualityMenu => _streamInfo?.isReady ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createTracker();
    unawaited(_initializePlayer());
  }

  void _createTracker() {
    final id = widget.lectureId;
    if (id == null || id.isEmpty) return;
    _tracker = LectureWatchTracker(
      realtime: context.read<RealtimeService>(),
      lectureId: id,
      lectureTitle: widget.lectureTitle,
      lectureSubject: widget.lectureSubject,
    );
  }

  @override
  void didUpdateWidget(covariant PremiumVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _streamInfo = null;
      _activeUrl = null;
      unawaited(_initializePlayer());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (controller.value.isPlaying) {
          controller.pause();
          _syncTracker();
          unawaited(WakelockPlus.disable());
        }
      case AppLifecycleState.resumed:
        break;
    }
  }

  Future<void> _initializePlayer() async {
    await _disposeController();
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = null;
    });

    final isRemote = MediaUrl.isRemote(widget.videoPath);
    File? file;
    if (!isRemote) {
      file = File(widget.videoPath);
      if (!file.existsSync()) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'ملف الفيديو غير موجود على الجهاز';
        });
        return;
      }
    }

    String? networkUrl;
    if (isRemote) {
      _streamInfo ??= await resolveLectureStream(widget.videoPath);
      if (!mounted) return;
      networkUrl =
          _activeUrl ??
          MediaUrl.resolve(
            _streamInfo!.play.isNotEmpty ? _streamInfo!.play : widget.videoPath,
          );
    }

    VideoPlayerController? controller;
    try {
      final options = VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      );
      controller = isRemote
          ? VideoPlayerController.networkUrl(
              Uri.parse(networkUrl!),
              videoPlayerOptions: options,
            )
          : VideoPlayerController.file(file!, videoPlayerOptions: options);
      await controller.initialize();
      controller.setLooping(false);
      await controller.setPlaybackSpeed(_speed.value);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final duration = controller.value.duration;
      if (duration > Duration.zero) {
        widget.onDurationResolved?.call(duration);
      }

      if (_resumeAt > Duration.zero) {
        await controller.seekTo(_resumeAt);
      }
      final resumePlaying = _resumePlaying;
      _resumeAt = Duration.zero;
      _resumePlaying = false;

      controller.addListener(_onTick);
      setState(() {
        _controller = controller;
        _isInitializing = false;
        _activeUrl = networkUrl;
      });

      if (resumePlaying) {
        await controller.play();
        await WakelockPlus.enable();
      }
      _syncTracker();
      _revealControls();
    } catch (_) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'تعذّر تحميل الفيديو. حاول مرة أخرى.';
      });
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final v = c.value;
    _tracker?.onFrame(
      positionSeconds: v.position.inMilliseconds / 1000,
      durationSeconds: v.duration.inMilliseconds / 1000,
      playing: v.isPlaying,
    );
    final isBuffering = v.isBuffering && v.isPlaying;
    if (_buffering.value != isBuffering) _buffering.value = isBuffering;

    final ended = v.duration > Duration.zero && v.position >= v.duration;
    if (ended && !_reachedEnd) {
      _reachedEnd = true;
      _controlsVisible.value = true;
      _hideTimer?.cancel();
      unawaited(WakelockPlus.disable());
      _syncTracker();
    } else if (!ended && _reachedEnd && v.position < v.duration - _skip) {
      _reachedEnd = false;
    }
  }

  Future<void> _disposeController() async {
    _hideTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onTick);
      if (controller.value.isPlaying) {
        await WakelockPlus.disable();
      }
      await controller.dispose();
    }
  }

  void _syncTracker() {
    final c = _controller;
    final t = _tracker;
    if (c == null || t == null || !c.value.isInitialized) return;
    t.mark(
      positionSeconds: c.value.position.inMilliseconds / 1000,
      durationSeconds: c.value.duration.inMilliseconds / 1000,
      playing: c.value.isPlaying,
    );
  }

  void _revealControls() {
    _hideTimer?.cancel();
    _controlsVisible.value = true;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      final c = _controller;
      if (c != null && c.value.isPlaying) _controlsVisible.value = false;
    });
  }

  void _toggleControls() {
    if (_controlsVisible.value) {
      _hideTimer?.cancel();
      _controlsVisible.value = false;
    } else {
      _revealControls();
    }
  }

  Future<void> togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    _revealControls();
    if (c.value.isPlaying) {
      await c.pause();
      await WakelockPlus.disable();
    } else {
      if (c.value.duration > Duration.zero &&
          c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
      await WakelockPlus.enable();
    }
    _syncTracker();
  }

  Future<void> seekTo(Duration target) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final max = c.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target);
    await c.seekTo(clamped);
    _syncTracker();
  }

  Future<void> seekRelative(Duration offset) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    await seekTo(c.value.position + offset);
    _revealControls();
  }

  Future<void> doubleTapSeek(bool forward) async {
    await HapticFeedback.lightImpact();
    _flashCounter++;
    _seekFlash.value = _SeekFlash(forward, _flashCounter);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 550), () {
      _seekFlash.value = null;
    });
    await seekRelative(forward ? _doubleTapSkip : -_doubleTapSkip);
  }

  Future<void> setSpeed(double value) async {
    _speed.value = value;
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      await c.setPlaybackSpeed(value);
    }
    _revealControls();
  }

  void cycleFit() {
    _fit.value = _fit.value == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    _revealControls();
  }

  List<_QualityOption> qualityOptions() {
    final info = _streamInfo;
    if (info == null || !info.isReady) return const [];
    final autoUrl = MediaUrl.resolve(
      (info.hls != null && info.hls!.isNotEmpty) ? info.hls! : info.progressive,
    );
    return [
      _QualityOption('تلقائي', autoUrl),
      for (final v in info.variants)
        _QualityOption(v.name, MediaUrl.resolve(v.playlist)),
    ];
  }

  bool isActiveQuality(_QualityOption option) =>
      _qualityLabel.value == option.label || _activeUrl == option.url;

  Future<void> switchQuality(_QualityOption option) async {
    if (option.url == _activeUrl) return;
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      _resumeAt = c.value.position;
      _resumePlaying = c.value.isPlaying;
    }
    _activeUrl = option.url;
    _qualityLabel.value = option.label;
    await _initializePlayer();
  }

  Future<void> enterFullscreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    _fullscreen.value = true;
    _syncTracker();
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: motionDuration(context, AppMotion.standard),
        reverseTransitionDuration: motionDuration(context, AppMotion.quick),
        pageBuilder: (_, animation, _) => _FullscreenPage(host: this),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
    _fullscreen.value = false;
    _fit.value = BoxFit.contain;
    _syncTracker();
    if (mounted) setState(() {});
  }

  Future<void> retry() => _initializePlayer();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _flashTimer?.cancel();
    unawaited(_tracker?.dispose());
    _tracker = null;
    unawaited(_disposeController());
    _controlsVisible.dispose();
    _speed.dispose();
    _fit.dispose();
    _buffering.dispose();
    _fullscreen.dispose();
    _qualityLabel.dispose();
    _seekFlash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.black,
            child: ValueListenableBuilder<bool>(
              valueListenable: _fullscreen,
              builder: (context, fullscreen, _) {
                if (fullscreen) return const SizedBox.shrink();
                return _buildBody(context, fullscreen: false);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool fullscreen}) {
    if (_isInitializing) {
      return _PosterOverlay(
        posterPath: widget.posterPath,
        child: const _PlayerLoading(label: 'جاري تحميل الفيديو...'),
      );
    }
    if (_hasError) {
      return _PosterOverlay(
        posterPath: widget.posterPath,
        child: _PlayerError(message: _errorMessage ?? 'حدث خطأ', onRetry: retry),
      );
    }
    return _PlayerStage(host: this, fullscreen: fullscreen);
  }
}

class _FullscreenPage extends StatefulWidget {
  final _PremiumVideoPlayerState host;

  const _FullscreenPage({required this.host});

  @override
  State<_FullscreenPage> createState() => _FullscreenPageState();
}

class _FullscreenPageState extends State<_FullscreenPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _PlayerStage(host: widget.host, fullscreen: true),
    );
  }
}

class _PlayerStage extends StatelessWidget {
  final _PremiumVideoPlayerState host;
  final bool fullscreen;

  const _PlayerStage({required this.host, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    final controller = host.controller;
    if (controller == null) return const SizedBox.expand();

    return GestureDetector(
      onTap: host._toggleControls,
      onDoubleTapDown: (details) {
        final width = context.size?.width ?? MediaQuery.sizeOf(context).width;
        final forward = details.localPosition.dx > width / 2;
        host.doubleTapSeek(forward);
      },
      onDoubleTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoSurface(host: host, fullscreen: fullscreen),
          ValueListenableBuilder<bool>(
            valueListenable: host.buffering,
            builder: (context, buffering, _) => buffering
                ? const _PlayerLoading(
                    label: 'جاري التخزين المؤقت...',
                    compact: true,
                  )
                : const SizedBox.shrink(),
          ),
          _SeekFlashOverlay(host: host),
          ValueListenableBuilder<bool>(
            valueListenable: host.controlsVisible,
            builder: (context, visible, _) => AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: motionDuration(context, AppMotion.quick),
              curve: AppMotion.standardCurve,
              child: IgnorePointer(
                ignoring: !visible,
                child: _ControlsOverlay(host: host, fullscreen: fullscreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  final _PremiumVideoPlayerState host;
  final bool fullscreen;

  const _VideoSurface({required this.host, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    final controller = host.controller!;
    final size = controller.value.size;

    Widget video = ValueListenableBuilder<BoxFit>(
      valueListenable: host.fit,
      builder: (context, fit, _) => FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width == 0 ? 16 : size.width,
          height: size.height == 0 ? 9 : size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );

    if (fullscreen) {
      video = InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 1,
        maxScale: 4,
        child: SizedBox.expand(child: video),
      );
    }

    return Center(child: video);
  }
}

class _SeekFlashOverlay extends StatelessWidget {
  final _PremiumVideoPlayerState host;

  const _SeekFlashOverlay({required this.host});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_SeekFlash?>(
      valueListenable: host.seekFlash,
      builder: (context, flash, _) {
        if (flash == null) return const SizedBox.shrink();
        return Align(
          alignment: flash.forward
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: _SeekBadge(key: ValueKey(flash.id), forward: flash.forward),
          ),
        );
      },
    );
  }
}

class _SeekBadge extends StatefulWidget {
  final bool forward;

  const _SeekBadge({super.key, required this.forward});

  @override
  State<_SeekBadge> createState() => _SeekBadgeState();
}

class _SeekBadgeState extends State<_SeekBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.forward
                      ? Icons.fast_forward_rounded
                      : Icons.fast_rewind_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 4),
                Text(
                  '٣ ثوانٍ',
                  style: AppFonts.readex(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final _PremiumVideoPlayerState host;
  final bool fullscreen;

  const _ControlsOverlay({required this.host, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    final controller = host.controller!;
    final pad = fullscreen
        ? EdgeInsets.fromLTRB(
            16 + MediaQuery.viewPaddingOf(context).left,
            12,
            16 + MediaQuery.viewPaddingOf(context).right,
            14 + MediaQuery.viewPaddingOf(context).bottom,
          )
        : const EdgeInsets.fromLTRB(12, 10, 12, 10);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.72),
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: Padding(
        padding: pad,
        child: Column(
          children: [
            _TopBar(host: host, fullscreen: fullscreen),
            const Spacer(),
            _CenterControls(host: host),
            const Spacer(),
            _BottomBar(host: host, controller: controller, fullscreen: fullscreen),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final _PremiumVideoPlayerState host;
  final bool fullscreen;

  const _TopBar({required this.host, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (fullscreen)
          _RoundBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'رجوع',
            size: 38,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        const Spacer(),
        ValueListenableBuilder<BoxFit>(
          valueListenable: host.fit,
          builder: (context, fit, _) => _RoundBtn(
            icon: fit == BoxFit.cover
                ? Icons.fit_screen_rounded
                : Icons.aspect_ratio_rounded,
            label: fit == BoxFit.cover ? 'احتواء' : 'ملء الإطار',
            size: 38,
            onTap: host.cycleFit,
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<double>(
          valueListenable: host.speed,
          builder: (context, speed, _) => _PillBtn(
            label: '${_trimSpeed(speed)}×',
            icon: Icons.speed_rounded,
            onTap: () => _showSpeedSheet(context, host),
          ),
        ),
        if (host.hasQualityMenu) ...[
          const SizedBox(width: 8),
          ValueListenableBuilder<String>(
            valueListenable: host.qualityLabel,
            builder: (context, label, _) => _PillBtn(
              label: label,
              icon: Icons.hd_rounded,
              onTap: () => _showQualitySheet(context, host),
            ),
          ),
        ],
      ],
    );
  }
}

class _CenterControls extends StatelessWidget {
  final _PremiumVideoPlayerState host;

  const _CenterControls({required this.host});

  @override
  Widget build(BuildContext context) {
    final controller = host.controller!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundBtn(
          icon: Icons.replay_10_rounded,
          label: 'رجوع ١٠ ثوانٍ',
          onTap: () => host.seekRelative(-_skip),
        ),
        const SizedBox(width: 24),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final done =
                value.duration > Duration.zero &&
                value.position >= value.duration;
            return _RoundBtn(
              icon: done
                  ? Icons.replay_rounded
                  : (value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
              label: done
                  ? 'إعادة التشغيل'
                  : (value.isPlaying ? 'إيقاف مؤقت' : 'تشغيل'),
              size: 62,
              prominent: true,
              onTap: host.togglePlayPause,
            );
          },
        ),
        const SizedBox(width: 24),
        _RoundBtn(
          icon: Icons.forward_10_rounded,
          label: 'تقدّم ١٠ ثوانٍ',
          onTap: () => host.seekRelative(_skip),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final _PremiumVideoPlayerState host;
  final VideoPlayerController controller;
  final bool fullscreen;

  const _BottomBar({
    required this.host,
    required this.controller,
    required this.fullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScrubBar(controller: controller, onSeek: host.seekTo),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Text(
                    VideoFormatUtils.formatDuration(value.position),
                    style: AppFonts.readex(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    '  /  ',
                    style: AppFonts.readex(color: Colors.white54, fontSize: 11.5),
                  ),
                  Text(
                    VideoFormatUtils.formatDuration(value.duration),
                    style: AppFonts.readex(color: Colors.white70, fontSize: 11.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${VideoFormatUtils.formatDuration(_remaining(value))}',
                    style: AppFonts.readex(color: Colors.white54, fontSize: 11.5),
                  ),
                  const Spacer(),
                  _RoundBtn(
                    icon: fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    label: fullscreen ? 'إنهاء ملء الشاشة' : 'ملء الشاشة',
                    size: 38,
                    onTap: fullscreen
                        ? () => Navigator.of(context).maybePop()
                        : host.enterFullscreen,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Duration _remaining(VideoPlayerValue value) {
    final r = value.duration - value.position;
    return r.isNegative ? Duration.zero : r;
  }
}

class _ScrubBar extends StatefulWidget {
  final VideoPlayerController controller;
  final ValueChanged<Duration> onSeek;

  const _ScrubBar({required this.controller, required this.onSeek});

  @override
  State<_ScrubBar> createState() => _ScrubBarState();
}

class _ScrubBarState extends State<_ScrubBar> {
  double? _dragFraction;
  static const double _barHeight = 26;
  static const double _trackHeight = 4;

  VideoPlayerValue get _value => widget.controller.value;

  double get _playedFraction {
    if (_dragFraction != null) return _dragFraction!;
    final total = _value.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (_value.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  double get _bufferedFraction {
    final total = _value.duration.inMilliseconds;
    if (total <= 0) return 0;
    var end = 0;
    for (final range in _value.buffered) {
      if (range.end.inMilliseconds > end) end = range.end.inMilliseconds;
    }
    return (end / total).clamp(0.0, 1.0);
  }

  void _update(double localX, double width) {
    if (width <= 0) return;
    setState(() => _dragFraction = (localX / width).clamp(0.0, 1.0));
  }

  void _commit() {
    final fraction = _dragFraction;
    setState(() => _dragFraction = null);
    if (fraction == null) return;
    final total = _value.duration.inMilliseconds;
    if (total <= 0) return;
    widget.onSeek(Duration(milliseconds: (total * fraction).round()));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _value.duration > Duration.zero;
    final dragging = _dragFraction != null;

    return Semantics(
      slider: true,
      label: 'شريط التقدّم',
      value: '${(_playedFraction * 100).round()}٪',
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: enabled
                  ? (d) => _update(d.localPosition.dx, width)
                  : null,
              onHorizontalDragUpdate: enabled
                  ? (d) => _update(d.localPosition.dx, width)
                  : null,
              onHorizontalDragEnd: enabled ? (_) => _commit() : null,
              onHorizontalDragCancel: enabled
                  ? () => setState(() => _dragFraction = null)
                  : null,
              onTapDown: enabled ? (d) => _update(d.localPosition.dx, width) : null,
              onTapUp: enabled ? (_) => _commit() : null,
              child: SizedBox(
                height: _barHeight,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: _trackHeight,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _bufferedFraction,
                      child: Container(
                        height: _trackHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _playedFraction,
                      child: Container(
                        height: _trackHeight,
                        decoration: BoxDecoration(
                          gradient: AppColors.darkPrimaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(_playedFraction * 2 - 1, 0),
                      child: AnimatedContainer(
                        duration: motionDuration(context, AppMotion.instant),
                        width: dragging ? 16 : 12,
                        height: dragging ? 16 : 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final bool prominent;

  const _RoundBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: prominent
              ? Colors.white.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.14),
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: prominent ? 0.5 : 0.22),
              width: prominent ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.5,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppFonts.readex(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterOverlay extends StatelessWidget {
  final String? posterPath;
  final Widget child;

  const _PosterOverlay({required this.posterPath, required this.child});

  @override
  Widget build(BuildContext context) {
    final isRemote = MediaUrl.isRemote(posterPath);
    final hasPoster =
        posterPath != null &&
        posterPath!.isNotEmpty &&
        (isRemote || File(posterPath!).existsSync());

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPoster)
          isRemote
              ? Image.network(
                  MediaUrl.resolve(posterPath!),
                  fit: BoxFit.cover,
                  cacheWidth: 1280,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                )
              : Image.file(
                  File(posterPath!),
                  fit: BoxFit.cover,
                  cacheWidth: 1280,
                  gaplessPlayback: true,
                )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.secondary.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        Container(color: Colors.black.withValues(alpha: 0.45)),
        Center(child: child),
      ],
    );
  }
}

class _PlayerLoading extends StatelessWidget {
  final String label;
  final bool compact;

  const _PlayerLoading({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: compact ? Colors.black38 : Colors.transparent,
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoadingIndicator(size: compact ? 28 : 36),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              label,
              style: AppFonts.readex(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PlayerError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.readex(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('إعادة المحاولة', style: AppFonts.readex()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

String _trimSpeed(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

void _showSpeedSheet(BuildContext context, _PremiumVideoPlayerState host) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => _OptionSheet(
      title: 'سرعة التشغيل',
      children: [
        for (final s in _speeds)
          _OptionTile(
            label: s == 1.0 ? 'عادي (1×)' : '${_trimSpeed(s)}×',
            selected: host.speed.value == s,
            onTap: () {
              Navigator.pop(sheetContext);
              host.setSpeed(s);
            },
          ),
      ],
    ),
  );
}

void _showQualitySheet(BuildContext context, _PremiumVideoPlayerState host) {
  final options = host.qualityOptions();
  if (options.isEmpty) return;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => _OptionSheet(
      title: 'جودة الفيديو',
      children: [
        for (final option in options)
          _OptionTile(
            label: option.label,
            selected: host.isActiveQuality(option),
            onTap: () {
              Navigator.pop(sheetContext);
              host.switchQuality(option);
            },
          ),
      ],
    ),
  );
}

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _OptionSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppFonts.readex(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: AppFonts.readex(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected
              ? AppColors.icon(context)
              : AppColors.textPrimary(context),
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.icon(context))
          : null,
    );
  }
}
