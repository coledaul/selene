import '../../domain/models/app_settings.dart';
import '../../utils/result.dart';
import '../services/settings_preferences_service.dart';

abstract interface class SettingsRepository {
  Future<Result<AppSettings>> load();
  Future<Result<void>> saveDoubanDataSource(String value);
  Future<Result<void>> saveDoubanImageSource(String value);
  Future<Result<void>> saveM3u8ProxyUrl(String value);
  Future<Result<void>> savePreferSpeedTest(bool value);
  Future<Result<void>> saveLocalSearch(bool value);
}

final class DefaultSettingsRepository implements SettingsRepository {
  DefaultSettingsRepository({required SettingsPreferencesService service})
    : _service = service;

  final SettingsPreferencesService _service;

  @override
  Future<Result<AppSettings>> load() => _guard('无法读取应用设置', _service.load);

  @override
  Future<Result<void>> saveDoubanDataSource(String value) =>
      _guard('无法保存豆瓣数据源', () => _service.saveDoubanDataSource(value));

  @override
  Future<Result<void>> saveDoubanImageSource(String value) =>
      _guard('无法保存豆瓣图片源', () => _service.saveDoubanImageSource(value));

  @override
  Future<Result<void>> saveM3u8ProxyUrl(String value) =>
      _guard('无法保存 M3U8 代理', () => _service.saveM3u8ProxyUrl(value));

  @override
  Future<Result<void>> savePreferSpeedTest(bool value) =>
      _guard('无法保存播放源优选设置', () => _service.savePreferSpeedTest(value));

  @override
  Future<Result<void>> saveLocalSearch(bool value) =>
      _guard('无法保存本地搜索设置', () => _service.saveLocalSearch(value));

  Future<Result<T>> _guard<T>(
    String message,
    Future<T> Function() action,
  ) async {
    try {
      return Success<T>(await action());
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
