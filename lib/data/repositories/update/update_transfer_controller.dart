import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_update_transfer.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/result.dart';
import '../../services/update/update_download_service.dart';
import '../../services/update/update_package_file_service.dart';
import '../../services/update/update_permission_service.dart';
import '../../services/update/update_source_service.dart';
import 'update_download_plan.dart';

/// 管理单个 Android 更新包从排队到交付系统安装器的完整生命周期。
///
/// 版本提示和偏好持久化由 [DefaultUpdateRepository] 的调用方负责；本类只持有
/// 传输状态，确保插件事件、线路回退和校验结果都从同一状态机发出。
final class UpdateTransferController extends ChangeNotifier {
  UpdateTransferController({
    required UpdateDownloadService downloadService,
    required UpdatePackageVerifier packageFileService,
    required UpdatePermissionService permissionService,
    required UpdateSourceResolver sourceResolver,
  }) : _downloadService = downloadService,
       _packageFileService = packageFileService,
       _permissionService = permissionService,
       _sourceResolver = sourceResolver;

  static const _apkMimeType = 'application/vnd.android.package-archive';

  final UpdateDownloadService _downloadService;
  final UpdatePackageVerifier _packageFileService;
  final UpdatePermissionService _permissionService;
  final UpdateSourceResolver _sourceResolver;

  StreamSubscription<UpdateDownloadEvent>? _downloadSubscription;
  UpdateDownloadSource _downloadSource = UpdateDownloadSource.automatic;
  UpdateTransferState _transfer = const UpdateTransferState();
  UpdateDownloadPlan? _downloadPlan;
  int _operationGeneration = 0;
  bool _initialized = false;
  bool _disposed = false;

  bool get supportsInAppDownload => _downloadService.supported;
  UpdateDownloadSource get downloadSource => _downloadSource;
  UpdateTransferState get transfer => _transfer;
  bool get canChangeSource =>
      !_transfer.isActive && _transfer.phase != UpdateTransferPhase.paused;

  Future<void> initialize(UpdateDownloadSource source) async {
    _downloadSource = source;
    if (_initialized) {
      notifyListeners();
      return;
    }
    _downloadSubscription ??= _downloadService.updates.listen(
      (event) => unawaited(_handleDownloadEventSafely(event)),
    );
    final record = await _downloadService.initialize();
    _initialized = true;
    if (record == null) {
      notifyListeners();
      return;
    }
    _restore(record);
    notifyListeners();
    if (record.status == UpdateDownloadStatus.complete) {
      await _verify(record.request.taskId, record.request.asset);
    }
  }

  void setDownloadSource(UpdateDownloadSource source) {
    _downloadSource = source;
    notifyListeners();
  }

  Future<void> reconcile(AppVersionInfo versionInfo) async {
    final taskId = _transfer.taskId;
    if (taskId == null) return;
    if (_transfer.version != versionInfo.latestVersion) {
      await clear();
      return;
    }
    final trustedAsset = versionInfo.androidAsset;
    if (trustedAsset == null || trustedAsset != _transfer.asset) {
      await clear();
      return;
    }
    _setTransfer(_transfer.copyWith(asset: trustedAsset));
  }

  Future<void> clear() async {
    final taskId = _transfer.taskId;
    if (taskId == null) {
      if (_transfer.phase != UpdateTransferPhase.idle) {
        _setTransfer(const UpdateTransferState());
      }
      return;
    }
    _operationGeneration++;
    await _downloadService.remove(taskId, deleteFile: true);
    _setTransfer(const UpdateTransferState());
  }

  Future<Result<void>> startDownload(AppVersionInfo versionInfo) async {
    final asset = versionInfo.androidAsset;
    if (!supportsInAppDownload || asset == null) {
      return const FailureResult(
        AppFailure(kind: FailureKind.validation, message: '当前平台不支持应用内下载'),
      );
    }
    if (_transfer.version == versionInfo.latestVersion &&
        (_transfer.isActive ||
            _transfer.phase == UpdateTransferPhase.paused ||
            _transfer.phase == UpdateTransferPhase.readyToInstall)) {
      return const Success<void>(null);
    }

    final previousTaskId = _transfer.taskId;
    if (previousTaskId != null) {
      try {
        await _downloadService.remove(previousTaskId, deleteFile: true);
      } catch (error, stackTrace) {
        return _failure(FailureKind.storage, '无法清理旧版本更新包', error, stackTrace);
      }
    }

    _operationGeneration++;
    var priority = 5;
    try {
      // 通知权限只决定是否启用 Android 14+ UIDT，不影响普通后台下载。
      priority = await _permissionService.requestNotificationPermission()
          ? 0
          : 5;
    } catch (_) {}
    _downloadPlan = UpdateDownloadPlan(
      version: versionInfo.latestVersion,
      asset: asset,
      requestedSource: _downloadSource,
      priority: priority,
      candidates: _sourceResolver.resolve(asset, _downloadSource),
    );
    return _enqueueCandidate();
  }

  Future<Result<void>> _enqueueCandidate() async {
    final plan = _downloadPlan;
    if (plan == null || !plan.hasCandidate) {
      return _failTransfer('更新下载失败，请切换线路或使用浏览器下载');
    }

    final request = plan.currentRequest;
    _setTransfer(
      UpdateTransferState(
        phase: UpdateTransferPhase.queued,
        version: plan.version,
        asset: plan.asset,
        taskId: request.taskId,
        requestedSource: plan.requestedSource,
        activeSource: request.source,
        totalBytes: plan.asset.size,
      ),
    );

    try {
      if (await _downloadService.enqueue(request)) {
        return const Success<void>(null);
      }
      return await _tryNextCandidate('无法创建更新下载任务');
    } catch (error, stackTrace) {
      final fallback = await _tryNextCandidate('无法创建更新下载任务');
      return fallback.isSuccess
          ? fallback
          : _failure(FailureKind.platform, '无法创建更新下载任务', error, stackTrace);
    }
  }

  Future<Result<void>> _tryNextCandidate(String message) async {
    final taskId = _transfer.taskId;
    if (taskId != null) {
      try {
        await _downloadService.remove(taskId, deleteFile: true);
      } catch (error, stackTrace) {
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.failed,
            errorMessage: '切换更新下载线路失败，请重试',
          ),
        );
        return _failure(
          FailureKind.storage,
          '切换更新下载线路失败，请重试',
          error,
          stackTrace,
        );
      }
    }

    final plan = _downloadPlan;
    if (plan != null && plan.moveNext()) {
      return _enqueueCandidate();
    }
    return _failTransfer(message);
  }

  Future<void> _handleDownloadEventSafely(UpdateDownloadEvent event) async {
    try {
      await _handleDownloadEvent(event);
    } catch (_) {
      if (!_disposed && event.taskId == _transfer.taskId) {
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.failed,
            errorMessage: '处理更新下载状态失败，请重试',
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadEvent(UpdateDownloadEvent event) async {
    if (_disposed || event.taskId != _transfer.taskId) return;
    switch (event.status) {
      case UpdateDownloadStatus.queued:
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.queued,
            clearError: true,
          ),
        );
      case UpdateDownloadStatus.downloading:
        final progress = event.progress.clamp(0.0, 1.0);
        final total = event.totalBytes > 0
            ? event.totalBytes
            : _transfer.asset?.size ?? 0;
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.downloading,
            progress: progress,
            downloadedBytes: event.downloadedBytes > 0
                ? event.downloadedBytes
                : (total * progress).round(),
            totalBytes: total,
            clearError: true,
          ),
        );
      case UpdateDownloadStatus.paused:
        _setTransfer(_transfer.copyWith(phase: UpdateTransferPhase.paused));
      case UpdateDownloadStatus.complete:
        final asset = _transfer.asset;
        if (asset != null) await _verify(event.taskId, asset);
      case UpdateDownloadStatus.notFound:
        await _tryNextCandidate('更新文件不存在，请重新检查版本');
      case UpdateDownloadStatus.failed:
        await _tryNextCandidate(
          event.errorMessage?.trim().isNotEmpty == true
              ? '更新下载失败：${event.errorMessage}'
              : '更新下载失败，请切换线路或使用浏览器下载',
        );
      case UpdateDownloadStatus.cancelled:
        _setTransfer(_transfer.copyWith(phase: UpdateTransferPhase.cancelled));
    }
  }

  Future<void> _verify(String taskId, AppReleaseAsset asset) async {
    final generation = ++_operationGeneration;
    _setTransfer(
      _transfer.copyWith(
        phase: UpdateTransferPhase.verifying,
        progress: 1,
        downloadedBytes: asset.size,
        totalBytes: asset.size,
        clearError: true,
      ),
    );
    try {
      final path = await _downloadService.filePath(taskId);
      final valid =
          path != null && await _packageFileService.verify(path, asset);
      // 校验属于异步 I/O；取消或新任务开始后，旧结果不得覆盖当前状态。
      if (_disposed || generation != _operationGeneration) return;
      if (!valid) {
        await _downloadService.remove(taskId, deleteFile: true);
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.failed,
            errorMessage: '更新包完整性校验失败，文件已删除',
          ),
        );
        return;
      }
      _setTransfer(
        _transfer.copyWith(
          phase: UpdateTransferPhase.readyToInstall,
          clearError: true,
        ),
      );
    } catch (_) {
      if (!_disposed && generation == _operationGeneration) {
        try {
          await _downloadService.remove(taskId, deleteFile: true);
        } catch (_) {
          // 校验和清理均失败时仍必须落入确定的失败状态，供用户重新下载。
        }
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.failed,
            errorMessage: '无法校验更新包，请重新下载',
          ),
        );
      }
    }
  }

  Future<Result<void>> pause() => _taskAction(
    expected: UpdateTransferPhase.downloading,
    action: _downloadService.pause,
    successPhase: UpdateTransferPhase.paused,
    failureMessage: '暂停更新下载失败',
  );

  Future<Result<void>> resume() => _taskAction(
    expected: UpdateTransferPhase.paused,
    action: _downloadService.resume,
    successPhase: UpdateTransferPhase.queued,
    failureMessage: '继续更新下载失败',
  );

  Future<Result<void>> _taskAction({
    required UpdateTransferPhase expected,
    required Future<bool> Function(String taskId) action,
    required UpdateTransferPhase successPhase,
    required String failureMessage,
  }) async {
    final taskId = _transfer.taskId;
    if (_transfer.phase != expected || taskId == null) {
      return FailureResult(
        AppFailure(kind: FailureKind.conflict, message: failureMessage),
      );
    }
    try {
      if (!await action(taskId)) {
        return FailureResult(
          AppFailure(kind: FailureKind.platform, message: failureMessage),
        );
      }
      _setTransfer(_transfer.copyWith(phase: successPhase));
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.platform, failureMessage, error, stackTrace);
    }
  }

  Future<Result<void>> cancel() async {
    final taskId = _transfer.taskId;
    if (taskId == null || !_transfer.canCancel) {
      return const FailureResult(
        AppFailure(kind: FailureKind.conflict, message: '当前没有可取消的更新下载'),
      );
    }
    try {
      _operationGeneration++;
      await _downloadService.remove(taskId, deleteFile: true);
      _setTransfer(
        _transfer.copyWith(
          phase: UpdateTransferPhase.cancelled,
          progress: 0,
          downloadedBytes: 0,
          clearError: true,
        ),
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return _failure(FailureKind.storage, '取消更新下载失败', error, stackTrace);
    }
  }

  Future<Result<void>> install() async {
    final taskId = _transfer.taskId;
    if ((_transfer.phase != UpdateTransferPhase.readyToInstall &&
            _transfer.phase != UpdateTransferPhase.installerLaunched) ||
        taskId == null) {
      return const FailureResult(
        AppFailure(kind: FailureKind.conflict, message: '更新包尚未准备完成'),
      );
    }
    _setTransfer(
      _transfer.copyWith(
        phase: UpdateTransferPhase.awaitingPermission,
        clearError: true,
      ),
    );
    try {
      final permission = await _permissionService.ensureInstallPermission();
      if (permission != UpdateInstallPermission.granted) {
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.readyToInstall,
            errorMessage: permission == UpdateInstallPermission.denied
                ? '请在系统设置中允许 Selene 安装未知来源应用'
                : '当前平台不支持安装 APK',
          ),
        );
        return FailureResult(
          AppFailure(
            kind: FailureKind.authorization,
            message: _transfer.errorMessage!,
          ),
        );
      }
      if (!await _downloadService.openFile(taskId, mimeType: _apkMimeType)) {
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.readyToInstall,
            errorMessage: '无法打开系统安装器，请使用浏览器下载',
          ),
        );
        return const FailureResult(
          AppFailure(kind: FailureKind.platform, message: '无法打开系统安装器'),
        );
      }
      // 系统安装器已经接管，但应用无法据此断言用户完成了安装。
      _setTransfer(
        _transfer.copyWith(
          phase: UpdateTransferPhase.installerLaunched,
          clearError: true,
        ),
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      _setTransfer(
        _transfer.copyWith(
          phase: UpdateTransferPhase.readyToInstall,
          errorMessage: '无法打开系统安装器，请重试',
        ),
      );
      return _failure(FailureKind.platform, '无法打开系统安装器，请重试', error, stackTrace);
    }
  }

  void _restore(UpdateDownloadRecord record) {
    final request = record.request;
    _transfer = UpdateTransferState(
      phase: switch (record.status) {
        UpdateDownloadStatus.queued => UpdateTransferPhase.queued,
        UpdateDownloadStatus.downloading => UpdateTransferPhase.downloading,
        UpdateDownloadStatus.paused => UpdateTransferPhase.paused,
        UpdateDownloadStatus.complete => UpdateTransferPhase.verifying,
        UpdateDownloadStatus.cancelled => UpdateTransferPhase.cancelled,
        UpdateDownloadStatus.notFound ||
        UpdateDownloadStatus.failed => UpdateTransferPhase.failed,
      },
      version: request.version,
      asset: request.asset,
      taskId: request.taskId,
      requestedSource: _downloadSource,
      activeSource: request.source,
      progress: record.progress.clamp(0.0, 1.0),
      downloadedBytes: (request.asset.size * record.progress).round(),
      totalBytes: request.asset.size,
      errorMessage:
          record.status == UpdateDownloadStatus.failed ||
              record.status == UpdateDownloadStatus.notFound
          ? '上次更新下载失败，请重试'
          : null,
    );
  }

  Result<void> _failTransfer(String message) {
    _setTransfer(
      _transfer.copyWith(
        phase: UpdateTransferPhase.failed,
        errorMessage: message,
      ),
    );
    return FailureResult(
      AppFailure(kind: FailureKind.network, message: message),
    );
  }

  void _setTransfer(UpdateTransferState value) {
    if (_disposed) return;
    _transfer = value;
    notifyListeners();
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
    _operationGeneration++;
    unawaited(_downloadSubscription?.cancel());
    _downloadService.dispose();
    super.dispose();
  }
}
