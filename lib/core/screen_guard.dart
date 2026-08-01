import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Observes the native screen-capture guard.
///
/// The actual blocking happens in platform code — FLAG_SECURE on Android, a black
/// cover window on iOS — so nothing here is load-bearing for security. This just
/// surfaces the state to Dart so the UI can react (pausing a lecture, showing a
/// notice) without any screen having to know about platform channels.
///
/// Screenshots are deliberately left alone on both platforms.
class ScreenGuard extends ChangeNotifier {
  static const EventChannel _channel = EventChannel(
    'com.tareeqalmajd.studentapp/screen_guard',
  );

  StreamSubscription<dynamic>? _subscription;
  bool _isBeingCaptured = false;
  bool _isSupported = false;

  /// True while the screen is being recorded, mirrored or cast.
  bool get isBeingCaptured => _isBeingCaptured;

  /// False on platforms with no native guard attached (desktop, web, tests).
  bool get isSupported => _isSupported;

  void start() {
    if (_subscription != null) return;
    if (kIsWeb) return;

    try {
      _subscription = _channel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: _handleError,
        cancelOnError: false,
      );
    } on MissingPluginException {
      _isSupported = false;
    } catch (_) {
      _isSupported = false;
    }
  }

  void _handleEvent(dynamic event) {
    _isSupported = true;
    final captured = event == true;
    if (captured == _isBeingCaptured) return;
    _isBeingCaptured = captured;
    notifyListeners();
  }

  void _handleError(Object error) {
    // A missing channel just means no native guard on this platform. Never let
    // it surface as an unhandled stream error.
    _isSupported = false;
    if (_isBeingCaptured) {
      _isBeingCaptured = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
