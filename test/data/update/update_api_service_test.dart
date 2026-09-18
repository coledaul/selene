import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:selene/data/services/update/update_api_service.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('GitHubUpdateApiService', () {
    test('优先通过加速地址查询固定仓库，并保留 GitHub 发布页', () async {
      Uri? requestedUri;
      var requestCount = 0;
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter((options) {
          requestedUri = options.uri;
          requestCount++;
          return _jsonResponse(<String, Object?>{
            'tag_name': '1.8.3',
            'body': 'release notes',
            'html_url': 'https://github.com/coledaul/selene/releases/tag/1.8.3',
          });
        });
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();

      expect(
        requestedUri,
        Uri.parse(
          'https://gh-proxy.com/https://api.github.com/repos/coledaul/selene/releases/latest',
        ),
      );
      expect(result.valueOrNull?.latestVersion, '1.8.3');
      expect(requestCount, 1);
      expect(result.valueOrNull?.releaseNotes, 'release notes');
      expect(
        result.valueOrNull?.releaseUri,
        Uri.parse('https://github.com/coledaul/selene/releases/tag/1.8.3'),
      );
    });

    for (final scenario in [
      'timeout',
      'rateLimit',
      'notFound',
      'html',
      'invalidRelease',
    ]) {
      test('加速响应 $scenario 时只回退一次直连', () async {
        final requests = <Uri>[];
        final dio = Dio()
          ..httpClientAdapter = _UpdateAdapter((options) {
            requests.add(options.uri);
            if (options.uri.host == 'gh-proxy.com') {
              return switch (scenario) {
                'timeout' => throw DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionTimeout,
                ),
                'rateLimit' => ResponseBody.fromString('{}', 429),
                'notFound' => ResponseBody.fromString('{}', 404),
                'html' => ResponseBody.fromString(
                  '<html>unavailable</html>',
                  200,
                ),
                _ => _jsonResponse({
                  'tag_name': 'v1.8.3',
                  'html_url': 'https://example.com/releases/tag/v1.8.3',
                }),
              };
            }
            return _jsonResponse({
              'tag_name': 'v1.8.3',
              'html_url':
                  'https://github.com/coledaul/selene/releases/tag/v1.8.3',
            });
          });
        addTearDown(() => dio.close(force: true));
        final result = await GitHubUpdateApiService(
          dio: dio,
          packageInfo: () async => _packageInfo('1.8.2'),
        ).check();
        expect(result.valueOrNull?.latestVersion, '1.8.3');
        expect(requests.map((uri) => uri.host), [
          'gh-proxy.com',
          'api.github.com',
        ]);
      });
    }

    test('两条检测线路均失败时返回失败，不伪造已是最新版', () async {
      final requests = <Uri>[];
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter((options) {
          requests.add(options.uri);
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        });
      addTearDown(() => dio.close(force: true));
      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();
      expect(result.failureOrNull?.kind, FailureKind.timeout);
      expect(requests.map((uri) => uri.host), [
        'gh-proxy.com',
        'api.github.com',
      ]);
    });

    test('检查取消后不启动直连回退', () async {
      final requests = <Uri>[];
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter((options) {
          requests.add(options.uri);
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          );
        });
      addTearDown(() => dio.close(force: true));
      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();
      expect(result.failureOrNull?.kind, FailureKind.cancellation);
      expect(requests.map((uri) => uri.host), ['gh-proxy.com']);
    });

    test('服务已释放时不再发出检测请求', () async {
      var requests = 0;
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter((_) {
          requests++;
          return ResponseBody.fromString('{}', 500);
        });
      addTearDown(() => dio.close(force: true));
      final service = GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      );
      service.dispose();
      final result = await service.check();
      expect(result.failureOrNull?.kind, FailureKind.cancellation);
      expect(requests, 0);
    });

    test('支持带 v 前缀的发布标签', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.3',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.3',
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();

      expect(result.valueOrNull?.latestVersion, '1.8.3');
      expect(result.valueOrNull?.releaseUri.pathSegments.last, 'v1.8.3');
    });

    test('没有新版本时不返回更新信息', () async {
      var requests = 0;
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter((_) {
          requests++;
          return _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.2',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.2',
          });
        });
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
      expect(requests, 1);
    });

    test('拒绝跳转到目标仓库之外的发布页', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.3',
            'html_url': 'https://example.com/releases/tag/v1.8.3',
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();

      expect(result.failureOrNull?.kind, FailureKind.parsing);
      expect(result.failureOrNull?.message, '版本信息格式无效');
    });

    test('仓库尚无 Release 时返回明确错误', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => ResponseBody.fromString('not found', 404),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();

      expect(result.failureOrNull?.kind, FailureKind.notFound);
      expect(result.failureOrNull?.message, '更新源暂无已发布版本');
    });

    test('Android arm64 只选择严格匹配且带 GitHub 摘要的 APK', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.3',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.3',
            'assets': <Object?>[
              _asset(
                name: 'selene-1.8.3-armv7a.apk',
                size: 87,
                digest: 'sha256:${'b' * 64}',
              ),
              _asset(
                name: 'selene-1.8.3-armv8.apk',
                size: 66,
                digest: 'sha256:${'a' * 64}',
              ),
            ],
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
        isAndroid: () => true,
        androidArchitecture: () => AndroidArchitecture.arm64,
      ).check();

      final asset = result.valueOrNull?.androidAsset;
      expect(asset?.fileName, 'selene-1.8.3-armv8.apk');
      expect(asset?.size, 66);
      expect(asset?.sha256, 'a' * 64);
      expect(asset?.architecture, AndroidArchitecture.arm64);
      expect(
        asset?.downloadUri,
        Uri.parse(
          'https://github.com/coledaul/selene/releases/download/'
          'v1.8.3/selene-1.8.3-armv8.apk',
        ),
      );
    });

    test('Android 资产不可信或不唯一时保留 Release 页面但禁用应用内下载', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.3',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.3',
            'assets': <Object?>[
              _asset(
                name: 'selene-1.8.3-armv8.apk',
                size: 66,
                digest: 'sha256:${'a' * 64}',
              ),
              _asset(
                name: 'selene-1.8.3-armv8.apk',
                size: 66,
                digest: 'sha256:${'a' * 64}',
              ),
            ],
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
        isAndroid: () => true,
        androidArchitecture: () => AndroidArchitecture.arm64,
      ).check();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.androidAsset, isNull);
      expect(result.valueOrNull?.releaseUri.host, 'github.com');
    });

    test('Android 非 ARM 运行架构不猜测 APK 并保留外部 Release 行为', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.3',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.3',
            'assets': <Object?>[
              _asset(
                name: 'selene-1.8.3-armv8.apk',
                size: 66,
                digest: 'sha256:${'a' * 64}',
              ),
            ],
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
        isAndroid: () => true,
        androidArchitecture: () => null,
      ).check();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.androidAsset, isNull);
      expect(result.valueOrNull?.releaseUri.host, 'github.com');
    });

    test('非 Android 平台不解析 APK 资产并保持外部 Release 行为', () async {
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.3',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.3',
            'assets': <Object?>[
              _asset(
                name: 'selene-1.8.3-armv8.apk',
                size: 66,
                digest: 'sha256:${'a' * 64}',
              ),
            ],
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
        isAndroid: () => false,
      ).check();

      expect(result.valueOrNull?.androidAsset, isNull);
      expect(result.valueOrNull?.releaseUri.host, 'github.com');
    });
  });
}

Map<String, Object?> _asset({
  required String name,
  required int size,
  required String digest,
}) => <String, Object?>{
  'name': name,
  'state': 'uploaded',
  'content_type': 'application/vnd.android.package-archive',
  'size': size,
  'digest': digest,
  'browser_download_url':
      'https://github.com/coledaul/selene/releases/download/v1.8.3/$name',
};

PackageInfo _packageInfo(String version) => PackageInfo(
  appName: 'Selene',
  packageName: 'org.moontechlab.selene',
  version: version,
  buildNumber: '1',
);

ResponseBody _jsonResponse(Map<String, Object?> value) =>
    ResponseBody.fromString(
      jsonEncode(value),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );

final class _UpdateAdapter implements HttpClientAdapter {
  _UpdateAdapter(this.callback);

  final ResponseBody Function(RequestOptions options) callback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => callback(options);

  @override
  void close({bool force = false}) {}
}
