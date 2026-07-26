import '../../domain/models/app_version.dart';
import '../../utils/result.dart';
import '../services/update_api_service.dart';
import '../services/update_preferences_service.dart';

abstract interface class UpdateRepository {
  Future<Result<AppVersionInfo?>> check({bool respectPromptPolicy = true});
  Future<Result<void>> dismiss(String version);
  void dispose();
}

final class DefaultUpdateRepository implements UpdateRepository {
  DefaultUpdateRepository({
    required UpdateApiService apiService,
    required UpdatePreferencesService preferencesService,
    DateTime Function()? now,
  }) : _apiService = apiService,
       _preferencesService = preferencesService,
       _now = now ?? DateTime.now;

  final UpdateApiService _apiService;
  final UpdatePreferencesService _preferencesService;
  final DateTime Function() _now;
  bool _disposed = false;

  @override
  Future<Result<AppVersionInfo?>> check({
    bool respectPromptPolicy = true,
  }) async {
    final result = await _apiService.check();
    return switch (result) {
      Success<AppVersionInfo?>(:final value) when value == null =>
        const Success<AppVersionInfo?>(null),
      Success<AppVersionInfo?>(:final value) =>
        respectPromptPolicy
            ? await _promptable(value!)
            : Success<AppVersionInfo?>(value),
      FailureResult<AppVersionInfo?>(:final failure) => FailureResult(failure),
    };
  }

  Future<Result<AppVersionInfo?>> _promptable(AppVersionInfo value) async {
    try {
      final shouldPrompt = await _preferencesService.shouldPrompt(
        value.latestVersion,
        _now(),
      );
      return Success<AppVersionInfo?>(shouldPrompt ? value : null);
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: '无法读取更新提示设置',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> dismiss(String version) async {
    try {
      await _preferencesService.dismiss(version);
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: '无法保存忽略版本设置',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _apiService.dispose();
  }
}
