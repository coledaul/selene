import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('品牌色只在共享 tokens 定义，业务 UI 不重建主题', () {
    final violations = <String>[];
    for (final file in Directory(
      'lib/ui',
    ).listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || path.contains('/core/themes/')) continue;
      final source = file.readAsStringSync();
      if (RegExp(
        r'Color\(0xFF(?:27ae60|52c77a|2ecc71)\)',
        caseSensitive: false,
      ).hasMatch(source)) {
        violations.add('$path 重复定义品牌色');
      }
      if (RegExp(
        r'\bThemeData\s*\(|\bColorScheme\.fromSeed\s*\(',
      ).hasMatch(source)) {
        violations.add('$path 重新构造主题');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
