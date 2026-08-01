import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/core.dart';
import 'theme/theme.dart';
import 'routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the status and navigation bars from the first frame. Android
  // 15 enforces this for apps targeting SDK 35 anyway, and setting it up front
  // means the insets the layout code reads are the real ones rather than
  // changing the first time the video player exits fullscreen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  ApiClient.initialize();

  final dataService = ApiDataService();
  final settingsService = AppSettingsService();
  final authService = AuthService(dataService);
  final realtimeService = RealtimeService();
  final screenGuard = ScreenGuard()..start();
  final notifications = NotificationService();

  // A push that arrives while the app is open refreshes the data behind the
  // banner, so tapping it lands on content that is already loaded.
  notifications.onForegroundRefresh = dataService.refreshAll;

  await Future.wait<void>([
    dataService.initialize(),
    settingsService.initialize(),
    // Started early so a notification tap that launched the app is captured
    // before the first frame; it does not prompt for permission here.
    notifications.initialize(),
  ]);

  await authService.tryRestoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataService),
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: realtimeService),
        ChangeNotifierProvider.value(value: screenGuard),
        ChangeNotifierProvider.value(value: notifications),
      ],
      child: const TareeqAlmajdApp(),
    ),
  );
}

class TareeqAlmajdApp extends StatelessWidget {
  const TareeqAlmajdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppSettingsService, ThemeMode>(
      (s) => s.themeMode,
    );

    return MaterialApp.router(
      title: 'معهد طريق المجد للتعليم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: AppTheme.mediumAnimation,
      themeAnimationCurve: Curves.easeInOut,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return AppBackgroundLayer(
          child: MediaQuery(
            // Honour the system font size, but inside the range the layouts
            // are actually built for. These bounds match the ones
            // ResponsiveLayout.textScale assumes when it sizes rows and grid
            // extents, so the two never disagree about how tall text can get.
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.15,
              ),
            ),
            child: RealtimeBridge(
              child: PushBridge(child: child ?? const SizedBox.shrink()),
            ),
          ),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
      locale: const Locale('ar', 'AE'),
      routerConfig: AppRouter.router,
    );
  }
}

class RealtimeBridge extends StatefulWidget {
  final Widget child;

  const RealtimeBridge({super.key, required this.child});

  @override
  State<RealtimeBridge> createState() => _RealtimeBridgeState();
}

class _RealtimeBridgeState extends State<RealtimeBridge>
    with WidgetsBindingObserver {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final realtime = context.read<RealtimeService>();
    switch (state) {
      case AppLifecycleState.resumed:
        if (_loggedIn) unawaited(realtime.start());
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(realtime.stop());
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _sync(bool loggedIn) {
    if (_loggedIn == loggedIn) return;
    _loggedIn = loggedIn;
    final realtime = context.read<RealtimeService>();
    if (loggedIn) {
      unawaited(realtime.start());
    } else {
      unawaited(realtime.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthService, bool>((a) => a.isLoggedIn);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync(loggedIn);
    });
    return widget.child;
  }
}

/// Ties push notifications to the session.
///
/// Sits inside the router's builder so it is rebuilt on every auth change and
/// can navigate as soon as a tree exists — the two things the notification
/// service deliberately does not do itself.
class PushBridge extends StatefulWidget {
  final Widget child;

  const PushBridge({super.key, required this.child});

  @override
  State<PushBridge> createState() => _PushBridgeState();
}

class _PushBridgeState extends State<PushBridge> {
  NotificationService? _notifications;
  String? _identifiedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifications = context.read<NotificationService>();
    if (identical(notifications, _notifications)) return;
    _notifications?.removeListener(_drainPendingRoute);
    _notifications = notifications..addListener(_drainPendingRoute);
  }

  @override
  void dispose() {
    _notifications?.removeListener(_drainPendingRoute);
    super.dispose();
  }

  /// Navigates to whatever a tapped notification asked for.
  ///
  /// Deferred to after the frame because a cold-start tap fires before the
  /// router has built its first route, and pushing onto a navigator that does
  /// not exist yet is silently dropped.
  void _drainPendingRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifications = _notifications;
      if (notifications == null) return;

      // Only follow a deep link once there is a session to view it with;
      // otherwise the router's redirect would bounce it to /login and the
      // destination would be lost.
      if (!context.read<AuthService>().isLoggedIn) return;

      final route = notifications.takePendingRoute();
      if (route == null) return;
      AppRouter.router.push(route);
    });
  }

  Future<void> _syncSession(UserModel? user) async {
    final notifications = _notifications;
    if (notifications == null) return;

    if (user == null) {
      if (_identifiedUserId == null) return;
      _identifiedUserId = null;
      await notifications.forget();
      return;
    }

    final isNewSession = _identifiedUserId != user.id;
    _identifiedUserId = user.id;
    await notifications.identify(user);

    if (isNewSession) {
      // Asked here rather than at launch: the user has just signed in, so
      // "we'll tell you when a lecture is posted" is a request they have the
      // context to judge.
      await notifications.promptForPermission();
      // A tap that launched the app may have been waiting on this session.
      _drainPendingRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthService, UserModel?>((a) => a.currentUser);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_syncSession(user));
    });
    return widget.child;
  }
}
