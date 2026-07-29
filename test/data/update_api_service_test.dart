import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:selene/data/services/update_api_service.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('GitHubUpdateApiService', () {
    test('从独立仓库查询更新并使用 API 返回的发布页', () async {
      Uri? requestedUri;
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter((options) {
          requestedUri = options.uri;
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
          'https://api.github.com/repos/coledaul/selene/releases/latest',
        ),
      );
      expect(result.valueOrNull?.latestVersion, '1.8.3');
      expect(result.valueOrNull?.releaseNotes, 'release notes');
      expect(
        result.valueOrNull?.releaseUri,
        Uri.parse('https://github.com/coledaul/selene/releases/tag/1.8.3'),
      );
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
      final dio = Dio()
        ..httpClientAdapter = _UpdateAdapter(
          (_) => _jsonResponse(<String, Object?>{
            'tag_name': 'v1.8.2',
            'html_url':
                'https://github.com/coledaul/selene/releases/tag/v1.8.2',
          }),
        );
      addTearDown(() => dio.close(force: true));

      final result = await GitHubUpdateApiService(
        dio: dio,
        packageInfo: () async => _packageInfo('1.8.2'),
      ).check();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
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
  });
}

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
