import 'package:flutter/material.dart';
import 'app_motion.dart';

class AppTheme {
  static const Color olive = Color(0xFF5C6B32);
  static const Color gold = Color(0xFFC9A227);
  static const Color cream = Color(0xFFF6F1E6);
  static const Color darkBg = Color(0xFF070707);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkCard = Color(0xFF1C1C1C);

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SoftPageTransitionsBuilder(),
      TargetPlatform.iOS: SoftPageTransitionsBuilder(),
      TargetPlatform.windows: SoftPageTransitionsBuilder(),
      TargetPlatform.linux: SoftPageTransitionsBuilder(),
      TargetPlatform.macOS: SoftPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: olive,
      onPrimary: Colors.white,
      secondary: gold,
      onSecondary: Color(0xFF1A1214),
      surface: cream,
      onSurface: Color(0xFF2F351C),
      surfaceContainerHighest: Color(0xFFE8E2D2),
      outline: Color(0xFFC5BBA6),
      error: Color(0xFFB3261E),
    );
    return _withShared(ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: olive,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Color(0xFF1A1214),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        color: Colors.white.withValues(alpha: 0.92),
        shadowColor: olive.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ));
  }

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF1A1214),
      secondary: Color(0xFFD9D3C4),
      onSecondary: Color(0xFF111111),
      surface: darkSurface,
      onSurface: Color(0xFFF4EFE4),
      surfaceContainerHighest: darkCard,
      outline: Color(0xFF5C5344),
      error: Color(0xFFFFB4AB),
    );
    return _withShared(ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: gold,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Color(0xFF1A1214),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x55C9A227)),
        ),
      ),
    ));
  }

  static ThemeData _withShared(ThemeData base) {
    final scheme = base.colorScheme;
    return base.copyWith(
      pageTransitionsTheme: _pageTransitions,
      splashFactory: InkRipple.splashFactory,
      dividerColor: scheme.outline.withValues(alpha: 0.4),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? scheme.primary : scheme.outline;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        iconColor: scheme.primary,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: scheme.secondary,
        labelColor: base.appBarTheme.foregroundColor,
        unselectedLabelColor: base.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.94),
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        height: 70,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
      ),
    );
  }
}
