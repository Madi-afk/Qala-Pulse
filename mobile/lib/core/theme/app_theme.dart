import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const canvas = Color(0xFFF6F5F0);
  static const ink = Color(0xFF202D29);
  static const muted = Color(0xFF5E6B64);
  static const green = Color(0xFF24634C);
  static const softGreen = Color(0xFFE5EDE4);
  static const line = Color(0xFFDFE3DB);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppPalette.green,
          onPrimary: Colors.white,
          primaryContainer: AppPalette.softGreen,
          onPrimaryContainer: AppPalette.ink,
          surface: AppPalette.canvas,
          onSurface: AppPalette.ink,
          onSurfaceVariant: AppPalette.muted,
          outlineVariant: AppPalette.line,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'NotoSans',
    );
    final text = base.textTheme;
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.canvas,
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          height: 1.18,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
          height: 1.22,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
        bodySmall: text.bodySmall?.copyWith(
          color: AppPalette.muted,
          height: 1.5,
        ),
        labelSmall: text.labelSmall?.copyWith(
          color: AppPalette.muted,
          fontSize: 12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppPalette.canvas,
        foregroundColor: AppPalette.ink,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 64,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        shape: rounded.copyWith(side: const BorderSide(color: AppPalette.line)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.green, width: 2),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: rounded,
          side: const BorderSide(color: AppPalette.line),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        iconColor: AppPalette.green,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppPalette.green
                : AppPalette.muted,
          ),
        ),
        backgroundColor: AppPalette.canvas,
        indicatorColor: AppPalette.softGreen,
      ),
    );
  }
}
