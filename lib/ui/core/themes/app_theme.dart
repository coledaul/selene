import 'dart:io' show Platform;

import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primaryText = dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF2C3E50);
    final secondaryText = dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF7F8C8D);
    final fontFamily = Platform.isWindows ? 'Microsoft YaHei' : null;
    final textTheme = Platform.isWindows
        ? (dark ? ThemeData.dark() : ThemeData.light()).textTheme.copyWith(
            bodyLarge: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w400,
              fontFamily: fontFamily,
            ),
            bodyMedium: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w400,
              fontFamily: fontFamily,
            ),
            bodySmall: TextStyle(
              color: secondaryText,
              fontWeight: FontWeight.w400,
              fontFamily: fontFamily,
            ),
            titleLarge: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w500,
              fontFamily: fontFamily,
            ),
            titleMedium: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w500,
              fontFamily: fontFamily,
            ),
            titleSmall: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w500,
              fontFamily: fontFamily,
            ),
          )
        : TextTheme(
            bodyLarge: TextStyle(color: primaryText),
            bodyMedium: TextStyle(color: primaryText),
            bodySmall: TextStyle(color: secondaryText),
            titleLarge: TextStyle(color: primaryText),
            titleMedium: TextStyle(color: primaryText),
            titleSmall: TextStyle(color: primaryText),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2C3E50),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFFFFFF),
        foregroundColor: primaryText,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        elevation: 2,
      ),
      textTheme: textTheme,
      fontFamily: fontFamily,
    );
  }
}
