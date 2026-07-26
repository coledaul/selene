import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/subscription_repository.dart';
import 'package:selene/data/repositories/update_repository.dart';
import 'package:selene/data/services/subscription_api_service.dart';
import 'package:selene/data/services/subscription_local_service.dart';
import 'package:selene/data/services/update_api_service.dart';
import 'package:selene/data/services/update_preferences_service.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('外部 API Dio 所有权', () {
    test('订阅服务关闭内部创建的 Dio 且 dispose 幂等', () {
      final adapter = _TrackingAdapter();
      final service = DioSubscriptionApiService(
        dioFactory: () => Dio()..httpClientAdapter = adapter,
      );

      service
        ..dispose()
        ..dispose();

      expect(adapter.closeCount, 1);
    });

    test('订阅服务不关闭外部注入的 Dio', () {
      final adapter = _TrackingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = DioSubscriptionApiService(dio: dio);

      service.dispose();

      expect(adapter.closeCount, 0);
      dio.close(force: true);
      expect(adapter.closeCount, 1);
    });

    test('更新服务关闭内部创建的 Dio 且不关闭外部 Dio', () {
      final ownedAdapter = _TrackingAdapter();
      final owned = GitHubUpdateApiService(
        dioFactory: () => Dio()..httpClientAdapter = ownedAdapter,
      );
      final externalAdapter = _TrackingAdapter();
      final externalDio = Dio()..httpClientAdapter = externalAdapter;
      final external = GitHubUpdateApiService(dio: externalDio);

      owned
        ..dispose()
        ..dispose();
      external.dispose();

      expect(ownedAdapter.closeCount, 1);
      expect(externalAdapter.closeCount, 0);
      externalDio.close(force: true);
    });

    test('SubscriptionRepository 释放其持有的 API Service', () {
      final apiService = _FakeSubscriptionApiService();
      final repository = DefaultSubscriptionRepository(
        apiService: apiService,
        localService: _FakeSubscriptionLocalService(),
        invalidateCaches: () {},
      );

      repository
        ..dispose()
        ..dispose();

      expect(apiService.disposeCount, 1);
    });

    test('UpdateRepository 释放其持有的 API Service', () {
      final apiService = _FakeUpdateApiService();
      final repository = DefaultUpdateRepository(
        apiService: apiService,
        preferencesService: _FakeUpdatePreferencesService(),
      );

      repository
        ..dispose()
        ..dispose();

      expect(apiService.disposeCount, 1);
    });
  });
}

final class _TrackingAdapter implements HttpClientAdapter {
  int closeCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 200);

  @override
  void close({bool force = false}) => closeCount++;
}

final class _FakeSubscriptionApiService implements SubscriptionApiService {
  int disposeCount = 0;

  @override
  void dispose() => disposeCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSubscriptionLocalService implements SubscriptionLocalService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeUpdateApiService implements UpdateApiService {
  int disposeCount = 0;

  @override
  Future<Result<AppVersionInfo?>> check() async =>
      const Success<AppVersionInfo?>(null);

  @override
  void dispose() => disposeCount++;
}

final class _FakeUpdatePreferencesService implements UpdatePreferencesService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
