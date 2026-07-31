import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/update/update_download_plan.dart';
import 'package:selene/data/services/update/update_source_service.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';

void main() {
  test('自动线路首选加速地址不重试，回退直连后再启用重试', () {
    final plan = UpdateDownloadPlan(
      version: '1.8.4',
      asset: _asset(),
      requestedSource: UpdateDownloadSource.automatic,
      priority: 0,
      candidates: <UpdateSourceCandidate>[
        UpdateSourceCandidate(
          source: UpdateDownloadSource.proxy,
          uri: Uri.parse('https://gh-proxy.com/${_asset().downloadUri}'),
        ),
        UpdateSourceCandidate(
          source: UpdateDownloadSource.direct,
          uri: _asset().downloadUri,
        ),
      ],
    );

    expect(plan.currentRequest.taskId, 'selene-update-1.8.4-arm64-proxy');
    expect(plan.currentRequest.retries, 0);
    expect(plan.currentRequest.priority, 0);

    expect(plan.moveNext(), isTrue);
    expect(plan.currentRequest.taskId, 'selene-update-1.8.4-arm64-direct');
    expect(plan.currentRequest.retries, 2);
    expect(plan.moveNext(), isFalse);
  });

  test('用户手动指定的单线路保留插件重试', () {
    final plan = UpdateDownloadPlan(
      version: '1.8.4',
      asset: _asset(),
      requestedSource: UpdateDownloadSource.proxy,
      priority: 5,
      candidates: <UpdateSourceCandidate>[
        UpdateSourceCandidate(
          source: UpdateDownloadSource.proxy,
          uri: Uri.parse('https://gh-proxy.com/${_asset().downloadUri}'),
        ),
      ],
    );

    expect(plan.currentRequest.retries, 2);
    expect(plan.currentRequest.priority, 5);
  });
}

AppReleaseAsset _asset() => AppReleaseAsset(
  fileName: 'selene-1.8.4-armv8.apk',
  downloadUri: Uri.parse(
    'https://github.com/coledaul/selene/releases/download/'
    'v1.8.4/selene-1.8.4-armv8.apk',
  ),
  size: 66,
  sha256: 'a' * 64,
  architecture: AndroidArchitecture.arm64,
);
