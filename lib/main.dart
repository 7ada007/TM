import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/core.dart';
import 'theme/theme.dart';
import 'routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient.initialize();

  final dataService = ApiDataService();
  final settingsService = AppSettingsService();
  final authService = AuthService(dataService);
  final realtimeService = RealtimeService();

  await Future.wait<void>([
    dataService.initialize(),
    settingsService.initialize(),
  ]);

  await authService.tryRestoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataService),
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: realtimeService),
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
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.1,
              ),
            ),
            child: RealtimeBridge(child: child ?? const SizedBox.shrink()),
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
