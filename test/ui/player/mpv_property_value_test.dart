import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/mpv_property_value.dart';

void main() {
  test('比较 mpv 布尔、枚举、数值和字节大小的规范化回读值', () {
    expect(mpvPropertyValuesEquivalent('yes', 'yes'), isTrue);
    expect(mpvPropertyValuesEquivalent('immediate', 'immediate'), isTrue);
    expect(mpvPropertyValuesEquivalent('60', '60.000000'), isTrue);
    expect(mpvPropertyValuesEquivalent('32MiB', '33554432'), isTrue);
    expect(mpvPropertyValuesEquivalent('128MiB', '128 MiB'), isTrue);
  });

  test('拒绝空值和实际未生效的属性值', () {
    expect(mpvPropertyValuesEquivalent('yes', ''), isFalse);
    expect(mpvPropertyValuesEquivalent('yes', 'no'), isFalse);
    expect(mpvPropertyValuesEquivalent('32MiB', '16MiB'), isFalse);
  });
}
