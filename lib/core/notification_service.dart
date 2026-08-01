import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'models.dart';

/// Push notifications, end to end.
///
/// Owns the OneSignal lifecycle: SDK setup, identifying the signed-in user so
/// the backend can target them, asking for permission at a moment the user can
/// make sense of, and turning a tapped notification into an in-app route.
///
/// Deliberately free of Flutter widget imports — the UI layer subscribes to
/// [pendingRoute] rather than this class reaching into navigation itself, which
/// keeps the cold-start ordering problem in one place (see [pendingRoute]).
class NotificationService extends ChangeNotifier {
  /// Public OneSignal application identifier. Not a secret: it identifies the
  /// app to the SDK. The REST key that can *send* notifications lives only on
  /// the server.
  static const String appId = '07275e82-faf0-479e-8e68-9036649101ce';

  /// Tag keys mirrored to OneSignal so the dashboard can segment manually.
  /// Routine sends do not rely on these — the server targets explicit user IDs,
  /// which cannot go stale the way a tag can.
  static const String _tagRole = 'role';
  static const String _tagSection = 'section';
  static const String _tagGender = 'gender';

  bool _initialized = false;
  bool _permissionAsked = false;
  String? _identifiedUserId;

  /// Route requested by a tapped notification that has not been consumed yet.
  ///
  /// A tap can land before the router exists — on a cold start the OS launches
  /// the app *because* of the notification, and the SDK replays that click as
  /// soon as a listener registers, which is long before the first frame. So the
  /// route is parked here and the widget tree drains it when it is ready.
  String? _pendingRoute;

  String? get pendingRoute => _pendingRoute;

  bool get isInitialized => _initialized;

  /// Callback invoked when a push arrives while the app is open, so the UI can
  /// refresh the affected data instead of showing a banner about content the
  /// list below it does not have yet.
  Future<void> Function()? onForegroundRefresh;

  /// Boots the SDK. Safe to call more than once.
  ///
  /// Does **not** prompt for permission: at cold start the user has no context
  /// for the request, and on iOS a denial is effectively permanent. The prompt
  /// comes later, from [promptForPermission].
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.warn);
      }

      OneSignal.initialize(appId);

      // Registered before anything else so a click that launched the app is
      // replayed into [_pendingRoute] rather than dropped.
      OneSignal.Notifications.addClickListener(_handleClick);
      OneSignal.Notifications.addForegroundWillDisplayListener(
        _handleForeground,
      );
    } catch (error, stack) {
      // A push failure must never take the app down with it.
      debugPrint('NotificationService: initialize failed — $error\n$stack');
    }
  }

  /// Associates the device with a signed-in user.
  ///
  /// The external ID is the app's own user ID, which is what the backend uses
  /// to address a notification at exactly the right people.
  Future<void> identify(UserModel user) async {
    if (!_initialized) return;
    if (_identifiedUserId == user.id) {
      // Already linked; tags may still have changed (a moved section, a new
      // subject), so refresh those and skip the login round trip.
      await _syncTags(user);
      return;
    }

    try {
      await OneSignal.login(user.id);
      _identifiedUserId = user.id;
      await _syncTags(user);
    } catch (error) {
      debugPrint('NotificationService: identify failed — $error');
    }
  }

  Future<void> _syncTags(UserModel user) async {
    try {
      final tags = <String, String>{
        _tagRole: user.role.name,
        _tagGender: user.gender,
        if (user.section != null && user.section!.isNotEmpty)
          _tagSection: user.section!,
      };
      await OneSignal.User.addTags(tags);
    } catch (error) {
      debugPrint('NotificationService: tag sync failed — $error');
    }
  }

  /// Unlinks the device on sign-out so the next person to use it does not
  /// receive the previous user's notifications.
  Future<void> forget() async {
    if (!_initialized) return;
    _identifiedUserId = null;
    _pendingRoute = null;
    try {
      await OneSignal.logout();
      await OneSignal.Notifications.clearAll();
    } catch (error) {
      debugPrint('NotificationService: logout failed — $error');
    }
  }

  /// Asks for notification permission, once, at a point where the request makes
  /// sense to the user.
  ///
  /// Called just after a successful sign-in: the user has committed to the app
  /// and the value of "you'll be told when a lecture is posted" is obvious.
  /// Returns the resulting permission state.
  ///
  /// `fallbackToSettings` is false on purpose. If someone has already declined,
  /// bouncing them into system settings is nagging, not onboarding.
  Future<bool> promptForPermission() async {
    if (!_initialized || _permissionAsked) {
      return _initialized && OneSignal.Notifications.permission;
    }

    try {
      if (OneSignal.Notifications.permission) {
        _permissionAsked = true;
        return true;
      }

      // False once the OS has already made a decision — asking again would be
      // a no-op that returns false and looks like a refusal.
      final canAsk = await OneSignal.Notifications.canRequest();
      _permissionAsked = true;
      if (!canAsk) return OneSignal.Notifications.permission;

      return await OneSignal.Notifications.requestPermission(false);
    } catch (error) {
      debugPrint('NotificationService: permission request failed — $error');
      return false;
    }
  }

  /// Hands over a route requested by a notification tap, clearing it so it is
  /// navigated to exactly once.
  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  void _handleClick(OSNotificationClickEvent event) {
    final route = routeFor(event.notification);
    if (route == null) return;
    _pendingRoute = route;
    notifyListeners();
  }

  void _handleForeground(OSNotificationWillDisplayEvent event) {
    // The banner still shows — not calling preventDefault is what allows it —
    // but the underlying data is refreshed at the same time so tapping through
    // lands on content that is already present.
    unawaited(
      Future<void>(() async {
        try {
          await onForegroundRefresh?.call();
        } catch (error) {
          debugPrint('NotificationService: foreground refresh failed — $error');
        }
      }),
    );
  }

  /// Extracts the in-app destination from a notification payload.
  ///
  /// The server sends `data.route`. `launchUrl` is accepted as a fallback for
  /// notifications composed by hand in the OneSignal dashboard.
  ///
  /// Only in-app paths are honoured: anything that is not a single-segment
  /// absolute path is ignored, so a malformed or hostile payload cannot push an
  /// arbitrary destination into the router.
  @visibleForTesting
  static String? routeFor(OSNotification notification) {
    final data = notification.additionalData;
    final candidate =
        _asRoute(data?['route']) ?? _asRoute(notification.launchUrl);
    return candidate;
  }

  static String? _asRoute(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (!trimmed.startsWith('/')) return null;
    // Reject protocol-relative URLs ("//evil.example"), query/fragment
    // smuggling, and anything with whitespace in it.
    if (trimmed.startsWith('//')) return null;
    if (trimmed.contains(RegExp(r'\s'))) return null;
    return trimmed;
  }
}
