import 'package:flutter/material.dart';

import '../../../utils/font_utils.dart';

/// 字体加载与平台回退复用 FontUtils，这里只定义文字层级。
abstract final class AppTypography {
  static TextTheme create(ColorScheme colors) {
    TextStyle text(double size, {FontWeight weight = FontWeight.w400}) =>
        FontUtils.poppins(
          fontSize: size,
          fontWeight: weight,
          color: colors.onSurface,
        );
    return TextTheme(
      displayLarge: text(57),
      displayMedium: text(45),
      displaySmall: text(36),
      headlineLarge: text(32, weight: FontWeight.w600),
      headlineMedium: text(28, weight: FontWeight.w600),
      headlineSmall: text(24, weight: FontWeight.w600),
      titleLarge: text(20, weight: FontWeight.w600),
      titleMedium: text(18, weight: FontWeight.w600),
      titleSmall: text(14, weight: FontWeight.w600),
      bodyLarge: text(16),
      bodyMedium: text(14),
      bodySmall: text(12).copyWith(color: colors.onSurfaceVariant),
      labelLarge: text(15, weight: FontWeight.w600),
      labelMedium: text(14),
      labelSmall: text(12),
    );
  }
}
