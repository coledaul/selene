import 'package:flutter/foundation.dart';

import '../../../domain/models/app_update_transfer.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/result.dart';
import '../../services/update/update_api_service.dart';
import '../../services/update/update_download_service.dart';
import '../../services/update/update_launcher_service.dart';
import '../../services/update/update_package_file_service.dart';
import '../../services/update/update_permission_service.dart';
import '../../services/update/update_preferences_service.dart';
import '../../services/update/update_source_service.dart';
import 'update_transfer_controller.dart';

abstract interface class UpdateRepository implements Listenable {
  bool get supportsInAppDownload;
  UpdateDownloadSource get downloadSource;
  UpdateTransferState get transfer;

  Future<void> initialize();
  Future<Result<AppVersionInfo?>> check({bool respectPromptPolicy = true});
  Future<Result<void>> dismiss(String version);
  Future<Result<void>> setDownloadSource(UpdateDownloadSource source);
  Future<Result<void>> startDownload(AppVersionInfo versionInfo);
  Future<Result<void>> pause();
  Future<Result<void>> resume();
  Future<Result<void>> cancel();
  Future<Result<void>> install();
  Future<Result<void>> openRelease(AppVersionInfo versionInfo);
  void dispose();
}

/// 更新领域入口：负责版本提示策略，并将 Android 传输生命周期委托给控制器。
final class DefaultUpdateRepository extends ChangeNotifier
    implements UpdateRepository {
  DefaultUpdateRepository({
    required UpdateApiService apiService,
    required UpdatePreferencesService preferencesService,
    required UpdateDownloadService downloadService,
    required UpdatePackageVerifier packageFileService,
    required UpdatePermissionService permissionService,
    required UpdateLauncherService launcherService,
    UpdateSourceResolver sourceResolver = const UpdateSourceResolver(),
    DateTime Function()? now,
  }) : _apiService = apiService,
       _preferencesService = preferencesService,
       _launcherService = launcherService,
       _now = now ?? DateTime.now,
       _transferController = UpdateTransferController(
         downloadService: downloadService,
         packageFileService: packageFileService,
         permissionService: permissionService,
         sourceResolver: sourceResolver,
       ) {
    _transferController.addListener(_handleTransferChanged);
  }

  final UpdateApiService _apiService;
  final UpdatePreferencesService _preferencesService;
  final UpdateLauncherService _launcherService;
  final DateTime Function() _now;
  final UpdateTransferController _transferController;

  Future<void>? _initialization;
  bool _initialized = false;
  bool _disposed = false;

  @override
  bool get supportsInAppDownload => _transferController.supportsInAppDownload;

  @override
  UpdateDownloadSource get downloadSource => _transferController.downloadSource;

  @override
  UpdateTransferState get transfer => _transferController.transfer;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final current = _initialization;
    if (current != null) return current;

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
      _initialized = true;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initialize() async {
    final source = await _preferencesService.loadDownloadSource();
    await _transferController.initialize(source);
  }

  @override
  Future<Result<AppVersionInfo?>> check({
    bool respectPromptPolicy = true,
  }) async {
    final result = await _apiService.check();
    return switch (result) {
      Success<AppVersionInfo?>(:final value) when value == null =>
        await _checkedWithoutUpdate(),
      Success<AppVersionInfo?>(:final value) => await _checked(
        value!,
        respectPromptPolicy: respectPromptPolicy,
      ),
      FailureResult<AppVersionInfo?>(:final failure) => FailureResult(failure),
    };
  }

  Future<Result<AppVersionInfo?>> _checkedWithoutUpdate() async {
    try {
      await initialize();
      await _transferController.clear();
      return const Success<AppVersionInfo?>(null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '无法清理旧版本更新包', error, stackTrace);
    }
  }

  Future<Result<AppVersionInfo?>> _checked(
    AppVersionInfo value, {
    required bool respectPromptPolicy,
  }) async {
    try {
      await initialize();
      await _transferController.reconcile(value);
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '无法恢复更新下载状态', error, stackTrace);
    }
    return respectPromptPolicy
        ? _promptable(value)
        : Success<AppVersionInfo?>(value);
  }

  Future<Result<AppVersionInfo?>> _promptable(AppVersionInfo value) async {
    try {
      final shouldPrompt = await _preferencesService.shouldPrompt(
        value.latestVersion,
        _now(),
      );
      return Success<AppVersionInfo?>(shouldPrompt ? value : null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '无法读取更新提示设置', error, stackTrace);
    }
  }

  @override
  Future<Result<void>> dismiss(String version) async {
    try {
      await _preferencesService.dismiss(version);
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '无法保存忽略版本设置', error, stackTrace);
    }
  }

  @override
  Future<Result<void>> setDownloadSource(UpdateDownloadSource source) async {
    if (!_transferController.canChangeSource) {
      return const FailureResult(
        AppFailure(kind: FailureKind.conflict, message: '请先取消当前更新下载'),
      );
    }
    try {
      await _preferencesService.saveDownloadSource(source);
      _transferController.setDownloadSource(source);
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '无法保存更新下载线路', error, stackTrace);
    }
  }

  @override
  Future<Result<void>> startDownload(AppVersionInfo versionInfo) async {
    try {
      await initialize();
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '无法初始化更新下载', error, stackTrace);
    }
    return _transferController.startDownload(versionInfo);
  }

  @override
  Future<Result<void>> pause() => _transferController.pause();

  @override
  Future<Result<void>> resume() => _transferController.resume();

  @override
  Future<Result<void>> cancel() => _transferController.cancel();

  @override
  Future<Result<void>> install() => _transferController.install();

  @override
  Future<Result<void>> openRelease(AppVersionInfo versionInfo) async {
    try {
      if (!await _launcherService.open(versionInfo.releaseUri)) {
        return const FailureResult(
          AppFailure(kind: FailureKind.platform, message: '无法打开版本下载页面'),
        );
      }
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.platform, '无法打开版本下载页面', error, stackTrace);
    }
  }

  void _handleTransferChanged() {
    if (!_disposed) notifyListeners();
  }

  FailureResult<T> _failure<T>(
    FailureKind kind,
    String message,
    Object error,
    StackTrace stackTrace,
  ) => FailureResult<T>(
    AppFailure(
      kind: kind,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _transferController
      ..removeListener(_handleTransferChanged)
      ..dispose();
    _apiService.dispose();
    super.dispose();
  }
}
