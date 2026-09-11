import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const green = Color(0xFF356B57);
  static const ink = Color(0xFF203D32);
  static const background = Color(0xFFF7F7F2);
  static const softGreen = Color(0xFFEAF0E5);
  static const muted = Color(0xFF70786E);
  static const line = Color(0xFFE4E8DF);
  static const lime = Color(0xFFD8EEA7);
  static const amber = Color(0xFF8B5A26);
  static const softAmber = Color(0xFFF6EAD7);

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      onPrimary: Colors.white,
      surface: background,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: line,
    ),
    scaffoldBackgroundColor: background,
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ).apply(bodyColor: ink, displayColor: ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: softGreen,
      height: 76,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? ink : muted,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: green, width: 2),
      ),
    ),
  );
}
