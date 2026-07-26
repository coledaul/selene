import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/themes/app_theme.dart';

void main() {
  test('非 Windows 主题保持原有颜色且不额外强制字体和字重', () {
    if (Platform.isWindows) return;

    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.textTheme.bodyLarge?.color, const Color(0xFF2C3E50));
    expect(light.textTheme.bodySmall?.color, const Color(0xFF7F8C8D));
    expect(dark.textTheme.bodyLarge?.color, const Color(0xFFFFFFFF));
    expect(dark.textTheme.bodySmall?.color, const Color(0xFFB0B0B0));
    expect(light.textTheme.bodyLarge?.fontWeight, isNull);
    expect(light.textTheme.titleLarge?.fontWeight, isNull);
    expect(dark.textTheme.bodyLarge?.fontWeight, isNull);
    expect(dark.textTheme.titleLarge?.fontWeight, isNull);
  });
}
