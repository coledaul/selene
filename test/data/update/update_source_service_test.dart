import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/update/update_source_service.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';

void main() {
  const resolver = UpdateSourceResolver();
  final asset = AppReleaseAsset(
    fileName: 'selene-1.8.3-armv8.apk',
    downloadUri: Uri.parse(
      'https://github.com/coledaul/selene/releases/download/'
      'v1.8.3/selene-1.8.3-armv8.apk',
    ),
    size: 66,
    sha256: 'a' * 64,
    architecture: AndroidArchitecture.arm64,
  );

  test('自动线路严格按加速地址、GitHub 直连顺序返回候选', () {
    final candidates = resolver.resolve(asset, UpdateDownloadSource.automatic);

    expect(
      candidates.map((candidate) => candidate.source),
      <UpdateDownloadSource>[
        UpdateDownloadSource.proxy,
        UpdateDownloadSource.direct,
      ],
    );
    expect(candidates.first.uri.host, 'gh-proxy.com');
    expect(candidates.last.uri, asset.downloadUri);
  });

  test('手动线路只返回用户指定来源', () {
    expect(
      resolver.resolve(asset, UpdateDownloadSource.direct).single.source,
      UpdateDownloadSource.direct,
    );
    expect(
      resolver.resolve(asset, UpdateDownloadSource.proxy).single.source,
      UpdateDownloadSource.proxy,
    );
  });
}
