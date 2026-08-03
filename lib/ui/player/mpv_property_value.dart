final RegExp _byteSizePattern = RegExp(
  r'^([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*([kmgt]?i?b)?$',
  caseSensitive: false,
);

/// 比较 mpv 属性的期望值与规范化回读值。
bool mpvPropertyValuesEquivalent(String expected, String actual) {
  final normalizedExpected = expected.trim().toLowerCase();
  final normalizedActual = actual.trim().toLowerCase();
  if (normalizedExpected.isEmpty || normalizedActual.isEmpty) return false;
  if (normalizedExpected == normalizedActual) return true;

  final expectedNumber = double.tryParse(normalizedExpected);
  final actualNumber = double.tryParse(normalizedActual);
  if (expectedNumber != null && actualNumber != null) {
    return expectedNumber.isFinite &&
        actualNumber.isFinite &&
        expectedNumber == actualNumber;
  }

  final expectedBytes = _tryParseByteSize(normalizedExpected);
  final actualBytes = _tryParseByteSize(normalizedActual);
  return expectedBytes != null &&
      actualBytes != null &&
      expectedBytes == actualBytes;
}

int? _tryParseByteSize(String value) {
  final match = _byteSizePattern.firstMatch(value);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!);
  if (amount == null || !amount.isFinite || amount < 0) return null;
  final unit = match.group(2)?.toLowerCase() ?? '';
  final multiplier = switch (unit) {
    '' || 'b' => 1,
    'kb' => 1000,
    'kib' => 1024,
    'mb' => 1000 * 1000,
    'mib' => 1024 * 1024,
    'gb' => 1000 * 1000 * 1000,
    'gib' => 1024 * 1024 * 1024,
    'tb' => 1000 * 1000 * 1000 * 1000,
    'tib' => 1024 * 1024 * 1024 * 1024,
    _ => null,
  };
  if (multiplier == null) return null;
  return (amount * multiplier).round();
}
