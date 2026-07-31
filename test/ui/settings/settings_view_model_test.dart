import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/auth_repository.dart';
import 'package:selene/data/repositories/cache_repository.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/data/repositories/live_repository.dart';
import 'package:selene/data/repositories/settings_repository.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/domain/models/app_settings.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/ui/settings/view_models/settings_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('SettingsViewModel', () {
    late _FakeAuthRepository auth;
    late _FakeSettingsRepository settings;
    late _FakeCacheRepository cache;
    late _FakeLibraryRepository library;
    late _FakeLiveRepository live;
    late _FakeUpdateRepository update;
    late SettingsViewModel viewModel;

    setUp(() {
      auth = _FakeAuthRepository();
      settings = _FakeSettingsRepository();
      cache = _FakeCacheRepository();
      library = _FakeLibraryRepository();
      live = _FakeLiveRepository();
      update = _FakeUpdateRepository();
      viewModel = SettingsViewModel(
        authRepository: auth,
        settingsRepository: settings,
        updateRepository: update,
        cacheRepository: cache,
        libraryRepository: library,
        liveRepository: live,
      );
    });

    tearDown(() => viewModel.dispose());

    test('初始化统一读取设置和会话资料', () async {
      settings.loaded = const AppSettings(
        doubanDataSource: 'proxy',
        localSearch: true,
      );

      await viewModel.initialize();

      expect(viewModel.state.loading, isFalse);
      expect(viewModel.state.username, 'tester');
      expect(viewModel.state.role, 'admin');
      expect(viewModel.state.settings.doubanDataSource, 'proxy');
      expect(viewModel.state.settings.localSearch, isTrue);
    });

    test('设置只在 Repository 保存成功后更新 UI 状态', () async {
      await viewModel.initialize();
      settings.saveSucceeds = false;

      final failed = await viewModel.saveLocalSearch(true);
      expect(failed, isA<FailureResult<void>>());
      expect(viewModel.state.settings.localSearch, isFalse);

      settings.saveSucceeds = true;
      final succeeded = await viewModel.saveLocalSearch(true);
      expect(succeeded, isA<Success<void>>());
      expect(viewModel.state.settings.localSearch, isTrue);
    });

    test('退出命令只终止鉴权会话，缓存由应用会话边界统一清理', () async {
      final result = await viewModel.logout.execute();

      expect(result, isA<Success<void>>());
      expect(cache.clearCount, 0);
      expect(library.clearCount, 0);
      expect(live.clearCount, 0);
      expect(auth.logoutCount, 1);
    });

    test('用户主动清理仍会清空资料库、直播和全部内容缓存', () async {
      final result = await viewModel.clearCaches.execute();

      expect(result, isA<Success<void>>());
      expect(cache.clearCount, 1);
      expect(library.clearCount, 1);
      expect(live.clearCount, 1);
    });

    test('手动检查更新明确绕过自动提示频率', () async {
      update.available = AppVersionInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        releaseNotes: 'notes',
        releaseUri: Uri.parse('https://example.com/release'),
      );

      final result = await viewModel.checkUpdate.execute();

      expect(result, isA<Success<AppVersionInfo?>>());
      expect(update.lastRespectPromptPolicy, isFalse);
      expect(viewModel.state.availableUpdate?.latestVersion, '1.1.0');
    });
  });
}

final class _FakeAuthRepository extends ChangeNotifier
    implements AuthRepository {
  int logoutCount = 0;

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  AuthProfile get profile => const AuthProfile(username: 'tester');

  @override
  String get role => 'admin';

  @override
  Future<void> logout() async => logoutCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSettingsRepository implements SettingsRepository {
  AppSettings loaded = const AppSettings();
  bool saveSucceeds = true;

  Result<void> get _saveResult => saveSucceeds
      ? const Success<void>(null)
      : const FailureResult<void>(
          AppFailure(kind: FailureKind.storage, message: '保存失败'),
        );

  @override
  Future<Result<AppSettings>> load() async => Success<AppSettings>(loaded);

  @override
  Future<Result<void>> saveLocalSearch(bool value) async => _saveResult;

  @override
  Future<Result<void>> saveDoubanDataSource(String value) async => _saveResult;

  @override
  Future<Result<void>> saveDoubanImageSource(String value) async => _saveResult;

  @override
  Future<Result<void>> saveM3u8ProxyUrl(String value) async => _saveResult;

  @override
  Future<Result<void>> savePreferSpeedTest(bool value) async => _saveResult;
}

final class _FakeCacheRepository implements CacheRepository {
  int clearCount = 0;

  @override
  void clearSearchCache() {}

  @override
  Future<Result<void>> clearCatalogAndSearch() async {
    clearCount++;
    return const Success<void>(null);
  }

  @override
  void dispose() {}
}

final class _FakeLibraryRepository implements LibraryRepository {
  int clearCount = 0;

  @override
  void clearAllCache() => clearCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLiveRepository implements LiveRepository {
  int clearCount = 0;

  @override
  void clearAllCache() => clearCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeUpdateRepository extends ChangeNotifier
    implements UpdateRepository {
  AppVersionInfo? available;
  bool? lastRespectPromptPolicy;

  @override
  Future<Result<AppVersionInfo?>> check({
    bool respectPromptPolicy = true,
  }) async {
    lastRespectPromptPolicy = respectPromptPolicy;
    return Success<AppVersionInfo?>(available);
  }

  @override
  Future<Result<void>> dismiss(String version) async =>
      const Success<void>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
