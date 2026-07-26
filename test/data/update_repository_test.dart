import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/update_repository.dart';
import 'package:selene/data/services/update_api_service.dart';
import 'package:selene/data/services/update_preferences_service.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('已忽略或一天内提示过的版本不会再次暴露给 UI', () async {
    final version = AppVersionInfo(
      currentVersion: '1.0.0',
      latestVersion: '1.1.0',
      releaseNotes: '',
      releaseUri: Uri.parse('https://example.com/v1.1.0'),
    );
    final repository = DefaultUpdateRepository(
      apiService: _FakeUpdateApiService(version),
      preferencesService: _FakeUpdatePreferencesService(shouldPrompt: false),
    );

    final result = await repository.check();

    expect(result.valueOrNull, isNull);
    expect(result.isSuccess, isTrue);
  });

  test('偏好存储失败会保留 storage 类型错误', () async {
    final repository = DefaultUpdateRepository(
      apiService: _FakeUpdateApiService(null),
      preferencesService: _ThrowingUpdatePreferencesService(),
    );

    final result = await repository.dismiss('1.1.0');

    expect(result.failureOrNull?.kind, FailureKind.storage);
  });
}

final class _FakeUpdateApiService implements UpdateApiService {
  _FakeUpdateApiService(this.value);

  final AppVersionInfo? value;

  @override
  Future<Result<AppVersionInfo?>> check() async => Success(value);

  @override
  void dispose() {}
}

final class _FakeUpdatePreferencesService implements UpdatePreferencesService {
  _FakeUpdatePreferencesService({required bool shouldPrompt})
    : _shouldPrompt = shouldPrompt;

  final bool _shouldPrompt;

  @override
  Future<void> dismiss(String version) async {}

  @override
  Future<bool> shouldPrompt(String version, DateTime now) async =>
      _shouldPrompt;
}

final class _ThrowingUpdatePreferencesService
    implements UpdatePreferencesService {
  @override
  Future<void> dismiss(String version) => throw StateError('unavailable');

  @override
  Future<bool> shouldPrompt(String version, DateTime now) async => true;
}
