import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/themes/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('全局主题直接提供绿色控件与中性弹窗 dark=$dark', (tester) async {
      final theme = dark ? AppTheme.dark : AppTheme.light;
      expect(theme.colorScheme.primary, const Color(0xFF27AE60));
      expect(theme.colorScheme.secondary, const Color(0xFF27AE60));
      expect(
        theme.dialogTheme.backgroundColor,
        dark ? const Color(0xFF2C2C2C) : Colors.white,
      );
      expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
      expect(theme.progressIndicatorTheme.color, theme.colorScheme.primary);
      final button = theme.filledButtonTheme.style!;
      expect(button.backgroundColor!.resolve({}), theme.colorScheme.primary);
      expect(
        button.backgroundColor!.resolve({WidgetState.disabled}),
        isNot(theme.colorScheme.primary),
      );
      expect(
        (button.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(8),
      );
      expect(
        (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      expect(theme.textTheme.titleMedium?.fontSize, 18);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(
        theme.iconButtonTheme.style!.foregroundColor!.resolve({
          WidgetState.selected,
        }),
        theme.colorScheme.primary,
      );
      expect(
        theme.iconButtonTheme.style!.foregroundColor!.resolve({
          WidgetState.disabled,
        }),
        isNot(theme.colorScheme.primary),
      );
    });
  }

  testWidgets('文字层级共用项目字体与平台回退', (tester) async {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.textTheme.bodyLarge?.color, const Color(0xFF2C3E50));
    expect(
      light.textTheme.bodySmall?.color,
      light.colorScheme.onSurfaceVariant,
    );
    expect(dark.textTheme.bodyLarge?.color, const Color(0xFFFFFFFF));
    expect(dark.textTheme.bodySmall?.color, dark.colorScheme.onSurfaceVariant);
    for (final theme in [light, dark]) {
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        Platform.isWindows ? 'Microsoft YaHei' : startsWith('Poppins'),
      );
    }
  });
}
