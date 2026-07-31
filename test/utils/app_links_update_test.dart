import 'package:flutter_test/flutter_test.dart';
import 'package:selene/utils/app_links.dart';

void main() {
  test('只为严格合法的 GitHub Release 资产构造固定加速地址', () {
    final original = Uri.parse(
      'https://github.com/coledaul/selene/releases/download/'
      'v1.8.3/selene-1.8.3-armv8.apk',
    );

    expect(AppLinks.isReleaseAssetUri(original, tag: 'v1.8.3'), isTrue);
    expect(
      AppLinks.releaseAssetProxyUri(original),
      Uri.parse('https://gh-proxy.com/$original'),
    );
  });

  test('拒绝仓库外、带查询参数或非 HTTPS 的资产地址', () {
    final invalid = <Uri>[
      Uri.parse(
        'https://example.com/coledaul/selene/releases/download/'
        'v1.8.3/selene-1.8.3-armv8.apk',
      ),
      Uri.parse(
        'https://github.com/coledaul/selene/releases/download/'
        'v1.8.3/selene-1.8.3-armv8.apk?token=secret',
      ),
      Uri.parse(
        'http://github.com/coledaul/selene/releases/download/'
        'v1.8.3/selene-1.8.3-armv8.apk',
      ),
    ];

    for (final uri in invalid) {
      expect(AppLinks.isReleaseAssetUri(uri, tag: 'v1.8.3'), isFalse);
    }
  });
}
