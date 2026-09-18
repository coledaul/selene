import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// 原生 Material 控件的项目默认样式；页面只覆写真正的语义差异。
abstract final class AppComponentThemes {
  static ThemeData apply(ThemeData base) {
    final colors = base.colorScheme;
    final dark = base.brightness == Brightness.dark;
    const minimumSize = Size(AppMetrics.touchTarget, AppMetrics.touchTarget);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
    );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppMetrics.dialogRadius),
    );
    final filledStyle = FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      disabledBackgroundColor: dark
          ? const Color(0xFF3B3B3B)
          : const Color(0xFFEEEEEE),
      disabledForegroundColor: dark
          ? const Color(0xFF999999)
          : const Color(0xFF888888),
      minimumSize: minimumSize,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: base.textTheme.labelLarge,
      shape: buttonShape,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: dialogShape,
        titleTextStyle: base.textTheme.titleMedium,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        modalBackgroundColor: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppMetrics.dialogRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.iconButtonRadius),
        ),
        textStyle: base.textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(style: filledStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: filledStyle.copyWith(elevation: const WidgetStatePropertyAll(0)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: minimumSize,
          textStyle: base.textTheme.labelLarge,
          side: BorderSide(color: colors.outline),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.onSurfaceVariant,
          minimumSize: minimumSize,
          textStyle: base.textTheme.labelMedium,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style:
            IconButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              minimumSize: minimumSize,
              iconSize: AppMetrics.actionIcon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppMetrics.iconButtonRadius,
                ),
              ),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return colors.onSurface.withValues(alpha: 0.38);
                }
                if (states.contains(WidgetState.selected)) {
                  return colors.primary;
                }
                return colors.onSurfaceVariant;
              }),
            ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.primary.withValues(alpha: dark ? 0.18 : 0.12),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppMetrics.buttonRadius),
        ),
      ),
    );
  }
}
