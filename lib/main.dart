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
            child: child ?? const SizedBox.shrink(),
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
