import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';
import '../core/core.dart';

class AppColors {
  static const Color primary = Color(0xFF2058DB);
  static const Color primaryDeep = Color(0xFF1740A8);
  static const Color primaryBright = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF38A0F0);
  static const Color accent = Color(0xFF6FC1F8);

  static const Color backgroundLight = Color(0xFFF5F8FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFEFF4FB);

  static const Color backgroundDark = Color(0xFF0A101C);
  static const Color surfaceDark = Color(0xFF121A2A);
  static const Color darkSurfaceElevated = Color(0xFF182338);

  static const Color borderLight = Color(0xFFDFE7F3);
  static const Color borderDark = Color(0xFF283754);

  static const Color textPrimaryLight = Color(0xFF152642);
  static const Color textSecondaryLight = Color(0xFF5B6B84);

  static const Color textPrimaryDark = Color(0xFFECF2FB);
  static const Color textSecondaryDark = Color(0xFF9AA9C3);

  static const Color iconColor = Color(0xFF2058DB);
  static const Color iconColorDark = Color(0xFF7FB8F7);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF2E6FE8), Color(0xFF54A8F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color surface(BuildContext context) =>
      _isDark(context) ? darkSurfaceElevated : surfaceLight;

  static Color surfaceAlt(BuildContext context) =>
      _isDark(context) ? surfaceDark : surfaceAltLight;

  static Color border(BuildContext context) =>
      _isDark(context) ? borderDark : borderLight;

  static Color icon(BuildContext context) =>
      _isDark(context) ? iconColorDark : iconColor;

  static Color overlay([double opacity = 0.12]) {
    final base = Color.alphaBlend(
      Colors.white.withValues(alpha: (0.045 + opacity * 0.6).clamp(0.04, 0.22)),
      darkSurfaceElevated,
    );
    return Color.alphaBlend(
      secondary.withValues(alpha: (opacity * 0.55).clamp(0.0, 0.16)),
      base,
    );
  }

  static Color overlayBorder([double opacity = 0.14]) =>
      Colors.white.withValues(alpha: (opacity * 0.7).clamp(0.05, 0.16));

  static List<BoxShadow> darkShadow({double blur = 24}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: blur,
      offset: const Offset(0, 10),
    ),
  ];

  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFC2700A);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0369A1);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF38BDF8);

  static Color success_(BuildContext context) =>
      _isDark(context) ? successDark : success;

  static Color warning_(BuildContext context) =>
      _isDark(context) ? warningDark : warning;

  static Color error_(BuildContext context) =>
      _isDark(context) ? errorDark : error;

  static Color info_(BuildContext context) =>
      _isDark(context) ? infoDark : info;

  static Color roleBadgeBg(BuildContext context) => _isDark(context)
      ? secondary.withValues(alpha: 0.18)
      : primary.withValues(alpha: 0.08);

  static Color roleBadgeText(BuildContext context) =>
      _isDark(context) ? accent : primary;

  static Color roleBadgeBorder(BuildContext context) => _isDark(context)
      ? secondary.withValues(alpha: 0.35)
      : primary.withValues(alpha: 0.18);
}

abstract final class AppFonts {
  static TextTheme getTextTheme(Color primary, Color secondary) {
    final base = GoogleFonts.readexProTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyLarge: GoogleFonts.readexPro(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.readexPro(
        color: secondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.readexPro(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.readexPro(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: GoogleFonts.readexPro(
        color: secondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: GoogleFonts.readexPro(
        color: secondary,
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
    );
  }

  static String? get family => GoogleFonts.readexPro().fontFamily;

  static TextStyle readex({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.readexPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
}

abstract final class AppShadows {
  static List<BoxShadow> soft({Color? color, double blur = 16}) => [
    BoxShadow(
      color: (color ?? AppColors.primaryDeep).withValues(alpha: 0.06),
      blurRadius: blur * 1.5,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: (color ?? AppColors.primaryDeep).withValues(alpha: 0.04),
      blurRadius: blur * 0.5,
      spreadRadius: -2,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> of(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.38),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return soft();
  }

  static List<BoxShadow> raised(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.primaryDeep.withValues(alpha: 0.10),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: AppColors.primaryDeep.withValues(alpha: 0.05),
        blurRadius: 8,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

abstract final class AppLayout {
  static const double pageHorizontal = 20;
  static const double pageTop = 14;
  static const double pageBottom = 24;
  static const double sectionGap = 28;
  static const double blockGap = 18;
  static const double itemGap = 14;
  static const double cardGap = 16;
  static const double fabClearance = 84;
  static const double appBarHeight = 52;
  static const double bottomNavHeight = 60;

  static EdgeInsets pagePaddingOf(
    BuildContext context, {
    double bottomExtra = 0,
  }) {
    return ResponsiveLayout.of(context).pagePadding(bottomExtra: bottomExtra);
  }

  static EdgeInsets listPaddingOf(BuildContext context, {bool hasFab = false}) {
    return ResponsiveLayout.of(context).listPadding(hasFab: hasFab);
  }

  static double horizontalOf(BuildContext context) =>
      ResponsiveLayout.of(context).horizontalPadding;

  static double spacingOf(BuildContext context, double base) =>
      ResponsiveLayout.of(context).spacing(base);

  static EdgeInsets pagePadding({double bottomExtra = 0}) {
    return EdgeInsets.fromLTRB(
      pageHorizontal,
      pageTop,
      pageHorizontal,
      pageBottom + bottomExtra,
    );
  }

  static EdgeInsets listPadding({bool hasFab = false}) {
    return EdgeInsets.fromLTRB(
      pageHorizontal,
      0,
      pageHorizontal,
      pageBottom + (hasFab ? fabClearance : 0),
    );
  }
}

class AppTheme {
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);

  static ThemeData get lightTheme {
    final textTheme = AppFonts.getTextTheme(
      AppColors.textPrimaryLight,
      AppColors.textSecondaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.family,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.surfaceLight,
        surfaceContainerHighest: AppColors.surfaceAltLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.surfaceLight,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.iconColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppFonts.readex(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.iconColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shadowColor: AppColors.primaryDeep.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
          textStyle: AppFonts.readex(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppFonts.readex(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppFonts.readex(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        titleTextStyle: AppFonts.readex(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppFonts.readex(
          fontSize: 14,
          color: AppColors.textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        modalBackgroundColor: AppColors.surfaceLight,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppFonts.readex(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        labelStyle: AppFonts.readex(color: AppColors.textSecondaryLight),
        hintStyle: AppFonts.readex(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.65),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.iconColor,
        titleTextStyle: AppFonts.readex(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        subtitleTextStyle: AppFonts.readex(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
      dividerColor: AppColors.borderLight,
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceLight,
        elevation: 6,
        shadowColor: AppColors.primaryDeep.withValues(alpha: 0.18),
        textStyle: AppFonts.readex(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textSecondaryLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.borderLight;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondaryLight;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAltLight,
        circularTrackColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        selectedLabelStyle: AppFonts.readex(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppFonts.readex(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = AppFonts.getTextTheme(
      AppColors.textPrimaryDark,
      AppColors.textSecondaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.family,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBright,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.darkSurfaceElevated,
        surfaceContainerHighest: AppColors.surfaceDark,
        error: AppColors.errorDark,
        onPrimary: Colors.white,
        onSecondary: AppColors.backgroundDark,
        onSurface: AppColors.textPrimaryDark,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.darkSurfaceElevated,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.iconColorDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppFonts.readex(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.iconColorDark),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceElevated,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
          textStyle: AppFonts.readex(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppFonts.readex(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppFonts.readex(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        titleTextStyle: AppFonts.readex(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppFonts.readex(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: AppFonts.readex(
          color: AppColors.textPrimaryDark,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.primaryBright,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.errorDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1.6),
        ),
        labelStyle: AppFonts.readex(color: AppColors.textSecondaryDark),
        hintStyle: AppFonts.readex(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.65),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBright,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.iconColorDark,
        titleTextStyle: AppFonts.readex(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: AppFonts.readex(
          fontSize: 13,
          color: AppColors.textSecondaryDark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      dividerColor: AppColors.borderDark,
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurfaceElevated,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        textStyle: AppFonts.readex(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBright;
          }
          return AppColors.borderDark;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBright;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: AppColors.borderDark, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBright;
          }
          return AppColors.textSecondaryDark;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBright,
        linearTrackColor: AppColors.surfaceDark,
        circularTrackColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondaryDark,
        selectedLabelStyle: AppFonts.readex(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppFonts.readex(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
