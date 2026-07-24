import 'dart:async';

import 'realtime_service.dart';

class LectureWatchTracker {
  static const Duration reportInterval = Duration(seconds: 5);
  static const double _seekToleranceSeconds = 4.0;
  static const double _completionRatio = 0.95;

  final RealtimeService realtime;
  final String lectureId;
  final String lectureTitle;
  final String lectureSubject;

  Timer? _timer;
  double _lastPositionSeconds = 0;
  double _durationSeconds = 0;
  double _pendingDelta = 0;
  bool _playing = false;
  bool _completed = false;
  bool _started = false;
  bool _disposed = false;

  LectureWatchTracker({
    required this.realtime,
    required this.lectureId,
    required this.lectureTitle,
    required this.lectureSubject,
  });

  double get pendingDelta => _pendingDelta;

  void onFrame({
    required double positionSeconds,
    required double durationSeconds,
    required bool playing,
  }) {
    if (_disposed) return;

    if (durationSeconds > 0) _durationSeconds = durationSeconds;

    final advance = positionSeconds - _lastPositionSeconds;
    final isNaturalAdvance =
        _playing && advance > 0 && advance <= _seekToleranceSeconds;

    if (isNaturalAdvance) {
      _pendingDelta += advance;
    }

    _lastPositionSeconds = positionSeconds;

    if (_durationSeconds > 0 &&
        positionSeconds / _durationSeconds >= _completionRatio) {
      _completed = true;
    }

    final playingChanged = playing != _playing;
    _playing = playing;

    if (!_started) {
      _started = true;
      _report();
      _restartTimer();
      return;
    }

    if (playingChanged) {
      _report();
      _restartTimer();
    }
  }

  void mark({
    required double positionSeconds,
    required double durationSeconds,
    required bool playing,
  }) {
    if (_disposed || !_started) return;
    if (durationSeconds > 0) _durationSeconds = durationSeconds;
    _lastPositionSeconds = positionSeconds;
    _playing = playing;
    if (_durationSeconds > 0 &&
        positionSeconds / _durationSeconds >= _completionRatio) {
      _completed = true;
    }
    _report();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_playing || _disposed) return;
    _timer = Timer.periodic(reportInterval, (_) => _report());
  }

  void _report() {
    if (_disposed) return;
    final delta = _pendingDelta;
    final sent = realtime.reportProgress(
      lectureId: lectureId,
      lectureTitle: lectureTitle,
      lectureSubject: lectureSubject,
      positionSeconds: _lastPositionSeconds,
      durationSeconds: _durationSeconds,
      watchedDeltaSeconds: delta,
      playing: _playing,
      completed: _completed,
    );
    if (sent) {
      _pendingDelta -= delta;
      if (_pendingDelta < 0) _pendingDelta = 0;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;

    if (!_started) return;

    _playing = false;
    final delta = _pendingDelta;
    _pendingDelta = 0;

    var delivered = false;
    if (realtime.isConnected) {
      delivered = realtime.reportProgress(
        lectureId: lectureId,
        lectureTitle: lectureTitle,
        lectureSubject: lectureSubject,
        positionSeconds: _lastPositionSeconds,
        durationSeconds: _durationSeconds,
        watchedDeltaSeconds: delta,
        playing: false,
        completed: _completed,
      );
      if (delivered) {
        realtime.reportStopped(lectureId);
        return;
      }
    }

    await realtime.flushProgress(
      lectureId: lectureId,
      positionSeconds: _lastPositionSeconds,
      durationSeconds: _durationSeconds,
      watchedDeltaSeconds: delta,
      completed: _completed,
    );
  }
}
