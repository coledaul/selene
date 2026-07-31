import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/cache_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/live_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/update/update_repository.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_version.dart';
import '../../../domain/models/auth_models.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'settings_ui_state.dart';

final class SettingsViewModel extends ViewModel {
  SettingsViewModel({
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
    required UpdateRepository updateRepository,
    required CacheRepository cacheRepository,
    required LibraryRepository libraryRepository,
    required LiveRepository liveRepository,
  }) : _authRepository = authRepository,
       _settingsRepository = settingsRepository,
       _updateRepository = updateRepository,
       _cacheRepository = cacheRepository,
       _libraryRepository = libraryRepository,
       _liveRepository = liveRepository {
    logout = Command0<void>(_logout)..addListener(_commandChanged);
    clearCaches = Command0<void>(_clearCaches)..addListener(_commandChanged);
    checkUpdate = Command0<AppVersionInfo?>(_checkUpdate)
      ..addListener(_commandChanged);
    dismissUpdate = Command1<void, String>(_dismissUpdate)
      ..addListener(_commandChanged);
    _authRepository.addListener(_syncSession);
  }

  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final UpdateRepository _updateRepository;
  final CacheRepository _cacheRepository;
  final LibraryRepository _libraryRepository;
  final LiveRepository _liveRepository;
  SettingsUiState _state = const SettingsUiState();

  late final Command0<void> logout;
  late final Command0<void> clearCaches;
  late final Command0<AppVersionInfo?> checkUpdate;
  late final Command1<void, String> dismissUpdate;

  SettingsUiState get state => _state;

  Future<void> initialize() async {
    _setState(_state.copyWith(loading: true));
    final result = await _settingsRepository.load();
    final session = _authRepository;
    _setState(
      _state.copyWith(
        loading: false,
        localMode: session.status == AuthStatus.localMode,
        username: session.profile.username,
        role: session.role,
        settings: result.valueOrNull ?? const AppSettings(),
      ),
    );
  }

  Future<Result<void>> saveDoubanDataSource(String value) => _saveSetting(
    _settingsRepository.saveDoubanDataSource(value),
    (settings) => settings.copyWith(doubanDataSource: value),
  );

  Future<Result<void>> saveDoubanImageSource(String value) => _saveSetting(
    _settingsRepository.saveDoubanImageSource(value),
    (settings) => settings.copyWith(doubanImageSource: value),
  );

  Future<Result<void>> saveM3u8ProxyUrl(String value) => _saveSetting(
    _settingsRepository.saveM3u8ProxyUrl(value),
    (settings) => settings.copyWith(m3u8ProxyUrl: value.trim()),
  );

  Future<Result<void>> savePreferSpeedTest(bool value) => _saveSetting(
    _settingsRepository.savePreferSpeedTest(value),
    (settings) => settings.copyWith(preferSpeedTest: value),
  );

  Future<Result<void>> saveLocalSearch(bool value) => _saveSetting(
    _settingsRepository.saveLocalSearch(value),
    (settings) => settings.copyWith(localSearch: value),
  );

  Future<Result<void>> _saveSetting(
    Future<Result<void>> operation,
    AppSettings Function(AppSettings settings) update,
  ) async {
    final result = await operation;
    if (result.isSuccess) {
      _setState(_state.copyWith(settings: update(_state.settings)));
    }
    return result;
  }

  Future<Result<void>> _logout() async {
    try {
      await _authRepository.logout();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: '退出登录失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> _clearCaches() async {
    _libraryRepository.clearAllCache();
    _liveRepository.clearAllCache();
    return _cacheRepository.clearCatalogAndSearch();
  }

  Future<Result<AppVersionInfo?>> _checkUpdate() async {
    final result = await _updateRepository.check(respectPromptPolicy: false);
    if (result case Success<AppVersionInfo?>(:final value)) {
      _setState(_state.copyWith(availableUpdate: value));
    }
    return result;
  }

  Future<Result<void>> _dismissUpdate(String version) =>
      _updateRepository.dismiss(version);

  void consumeAvailableUpdate() {
    if (_state.availableUpdate != null) {
      _setState(_state.copyWith(availableUpdate: null));
    }
  }

  void _syncSession() {
    _setState(
      _state.copyWith(
        localMode: _authRepository.status == AuthStatus.localMode,
        username: _authRepository.profile.username,
        role: _authRepository.role,
      ),
    );
  }

  void _setState(SettingsUiState value) =>
      updateState(_state, value, (next) => _state = next);

  void _commandChanged() => notifyIfActive();

  @override
  void dispose() {
    _authRepository.removeListener(_syncSession);
    logout
      ..removeListener(_commandChanged)
      ..dispose();
    clearCaches
      ..removeListener(_commandChanged)
      ..dispose();
    checkUpdate
      ..removeListener(_commandChanged)
      ..dispose();
    dismissUpdate
      ..removeListener(_commandChanged)
      ..dispose();
    super.dispose();
  }
}
