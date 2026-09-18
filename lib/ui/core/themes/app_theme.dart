import 'package:flutter/material.dart';

import 'app_component_themes.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// 应用唯一主题入口：颜色角色 -> 文字层级 -> 控件样式。
abstract final class AppTheme {
  static final ThemeData light = _create(Brightness.light);
  static final ThemeData dark = _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF2C3E50);
    final surface = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final raisedSurface = dark ? const Color(0xFF2C2C2C) : Colors.white;
    final canvas = dark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final accentSurface = dark
        ? const Color(0xFF1C3B29)
        : const Color(0xFFE8F5ED);
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppBrand.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppBrand.primary,
          onPrimary: Colors.white,
          primaryContainer: accentSurface,
          onPrimaryContainer: foreground,
          secondary: AppBrand.primary,
          onSecondary: Colors.white,
          secondaryContainer: accentSurface,
          onSecondaryContainer: foreground,
          // 品牌色用于操作；页面、弹窗和菜单保持中性，不随种子色染色。
          surface: surface,
          onSurface: foreground,
          onSurfaceVariant: dark
              ? const Color(0xFFCCCCCC)
              : const Color(0xFF666666),
          surfaceDim: canvas,
          surfaceBright: raisedSurface,
          surfaceContainerLowest: canvas,
          surfaceContainerLow: surface,
          surfaceContainer: raisedSurface,
          surfaceContainerHigh: raisedSurface,
          surfaceContainerHighest: dark
              ? const Color(0xFF333333)
              : const Color(0xFFF5F5F5),
          surfaceTint: Colors.transparent,
          outline: dark ? const Color(0xFF666666) : const Color(0xFFBDBDBD),
          outlineVariant: dark
              ? const Color(0xFF404040)
              : const Color(0xFFE0E0E0),
          inverseSurface: dark
              ? const Color(0xFFF5F5F5)
              : const Color(0xFF2C2C2C),
          onInverseSurface: dark ? const Color(0xFF2C2C2C) : Colors.white,
        );
    return AppComponentThemes.apply(
      ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: colors,
        scaffoldBackgroundColor: canvas,
        textTheme: AppTypography.create(colors),
      ),
    );
  }
}
