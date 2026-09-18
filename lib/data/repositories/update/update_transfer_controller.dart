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
import 'pending_update_action.dart';
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
    Duration actionTimeout = const Duration(seconds: 15),
  }) : _downloadService = downloadService,
       _packageFileService = packageFileService,
       _permissionService = permissionService,
       _sourceResolver = sourceResolver,
       _actionTimeout = actionTimeout;

  static const _apkMimeType = 'application/vnd.android.package-archive';

  final UpdateDownloadService _downloadService;
  final UpdatePackageVerifier _packageFileService;
  final UpdatePermissionService _permissionService;
  final UpdateSourceResolver _sourceResolver;
  final Duration _actionTimeout;

  StreamSubscription<UpdateDownloadEvent>? _downloadSubscription;
  UpdateTransferState _transfer = const UpdateTransferState();
  UpdateDownloadPlan? _downloadPlan;
  int _operationGeneration = 0;
  bool _initialized = false;
  bool _disposed = false;
  bool _commandRunning = false;
  // 状态处理包含文件清理/校验，必须等待前一事件结束后再处理下一事件。
  Future<void> _eventQueue = Future<void>.value();
  PendingUpdateAction? _pendingAction;
  // 清理或切换线路时停止接收旧任务事件，但保留用于展示的传输快照。
  String? _eventTaskId;
  static int _attemptSequence = 0;

  Future<Result<void>> _exclusive(
    Future<Result<void>> Function() action,
  ) async {
    if (_disposed) return _superseded();
    if (_commandRunning) {
      return const FailureResult(
        AppFailure(kind: FailureKind.conflict, message: '更新操作正在处理中'),
      );
    }
    _commandRunning = true;
    try {
      return await action();
    } finally {
      _commandRunning = false;
    }
  }

  bool _current(int generation, [String? taskId]) =>
      !_disposed &&
      generation == _operationGeneration &&
      (taskId == null || taskId == _eventTaskId);

  Result<void> _superseded() => const FailureResult(
    AppFailure(kind: FailureKind.cancellation, message: '更新操作已取消'),
  );

  bool get supportsInAppDownload => _downloadService.supported;
  UpdateTransferState get transfer => _transfer;
  Future<void> initialize() async {
    if (_disposed) return;
    if (_initialized) {
      notifyListeners();
      return;
    }
    _downloadSubscription ??= _downloadService.updates.listen((event) {
      _eventQueue = _eventQueue.then((_) => _handleDownloadEventSafely(event));
    });
    final generation = _operationGeneration;
    final record = await _downloadService.initialize();
    if (!_current(generation)) return;
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
    final generation = ++_operationGeneration;
    _pendingAction?.cancel();
    _eventTaskId = null;
    _downloadPlan = null;
    final taskId = _transfer.taskId;
    if (taskId == null) {
      if (_transfer.phase != UpdateTransferPhase.idle) {
        _setTransfer(const UpdateTransferState());
      }
      return;
    }
    try {
      await _downloadService.remove(taskId, deleteFile: true);
      if (_current(generation)) _setTransfer(const UpdateTransferState());
    } catch (_) {
      if (_current(generation)) _failTransfer('无法清理更新包，请重试');
      rethrow;
    }
  }

  Future<Result<void>> startDownload(AppVersionInfo versionInfo) =>
      _exclusive(() => _startDownload(versionInfo));

  Future<Result<void>> _startDownload(AppVersionInfo versionInfo) async {
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

    final generation = ++_operationGeneration;
    final previousTaskId = _transfer.taskId;
    _eventTaskId = null;
    if (previousTaskId != null) {
      try {
        await _downloadService.remove(previousTaskId, deleteFile: true);
      } catch (error, stackTrace) {
        if (_current(generation)) _eventTaskId = previousTaskId;
        return _failure(FailureKind.storage, '无法清理旧版本更新包', error, stackTrace);
      }
    }

    if (!_current(generation)) return _superseded();
    var priority = 5;
    try {
      // 通知权限只决定是否启用 Android 14+ UIDT，不影响普通后台下载。
      priority = await _permissionService.requestNotificationPermission()
          ? 0
          : 5;
    } catch (_) {}
    if (!_current(generation)) return _superseded();
    _downloadPlan = UpdateDownloadPlan(
      version: versionInfo.latestVersion,
      asset: asset,
      requestedSource: UpdateDownloadSource.automatic,
      priority: priority,
      attemptId:
          '${DateTime.now().microsecondsSinceEpoch}-${_attemptSequence++}',
      candidates: _sourceResolver.resolve(
        asset,
        UpdateDownloadSource.automatic,
      ),
    );
    return _enqueueCandidate();
  }

  Future<Result<void>> _enqueueCandidate() async {
    final generation = _operationGeneration;
    final plan = _downloadPlan;
    if (plan == null || !plan.hasCandidate) {
      return _failTransfer('下载失败，请重试或使用浏览器下载');
    }

    final request = plan.currentRequest;
    _eventTaskId = request.taskId;
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
      final accepted = await _downloadService.enqueue(request);
      if (!_current(generation)) return _superseded();
      if (request.taskId != _eventTaskId || accepted) {
        return const Success<void>(null);
      }
      return await _tryNextCandidate('无法创建更新下载任务');
    } catch (error, stackTrace) {
      if (!_current(generation, request.taskId)) return _superseded();
      final fallback = await _tryNextCandidate('无法创建更新下载任务');
      return fallback.isSuccess
          ? fallback
          : _failure(FailureKind.platform, '无法创建更新下载任务', error, stackTrace);
    }
  }

  Future<Result<void>> _tryNextCandidate(String message) async {
    final generation = _operationGeneration;
    final taskId = _transfer.taskId;
    _eventTaskId = null;
    _setTransfer(_transfer.copyWith(phase: UpdateTransferPhase.queued));
    if (taskId != null) {
      try {
        await _downloadService.remove(taskId, deleteFile: true);
      } catch (error, stackTrace) {
        if (!_current(generation)) return _superseded();
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.failed,
            errorMessage: '下载失败，请重试',
          ),
        );
        return _failure(FailureKind.storage, '下载失败，请重试', error, stackTrace);
      }
    }

    if (!_current(generation)) return _superseded();
    final plan = _downloadPlan;
    if (plan != null && plan.moveNext()) {
      return _enqueueCandidate();
    }
    return _failTransfer(message);
  }

  Future<void> _handleDownloadEventSafely(UpdateDownloadEvent event) async {
    final generation = _operationGeneration;
    try {
      await _handleDownloadEvent(event);
    } catch (_) {
      if (_current(generation, event.taskId)) {
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
    if (_disposed || event.taskId != _eventTaskId) return;
    if (const {
      UpdateTransferPhase.verifying,
      UpdateTransferPhase.readyToInstall,
      UpdateTransferPhase.awaitingPermission,
      UpdateTransferPhase.installerLaunched,
      UpdateTransferPhase.cancelled,
      UpdateTransferPhase.failed,
    }.contains(_transfer.phase)) {
      return;
    }
    _pendingAction?.observe(event);
    switch (event.status) {
      case UpdateDownloadStatus.queued:
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.queued,
            clearError: true,
          ),
        );
      case UpdateDownloadStatus.downloading:
        if (event.progress != null &&
            _transfer.phase == UpdateTransferPhase.paused) {
          return;
        }
        final progress = event.progress?.clamp(0.0, 1.0) ?? _transfer.progress;
        final total = event.totalBytes > 0
            ? event.totalBytes
            : _transfer.asset?.size ?? 0;
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.downloading,
            progress: progress,
            downloadedBytes: event.progress == null
                ? _transfer.downloadedBytes
                : event.downloadedBytes > 0
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
        // 插件异常可能包含内部下载地址，不作为用户提示直接展示。
        await _tryNextCandidate('下载失败，请重试或使用浏览器下载');
      case UpdateDownloadStatus.cancelled:
        _setTransfer(_transfer.copyWith(phase: UpdateTransferPhase.cancelled));
    }
  }

  Future<void> _verify(String taskId, AppReleaseAsset asset) async {
    final generation = _operationGeneration;
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
        if (!_current(generation)) return;
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
        if (!_current(generation)) return;
        _setTransfer(
          _transfer.copyWith(
            phase: UpdateTransferPhase.failed,
            errorMessage: '无法校验更新包，请重新下载',
          ),
        );
      }
    }
  }

  Future<Result<void>> pause() => _exclusive(
    () => _taskAction(
      expected: UpdateTransferPhase.downloading,
      action: _downloadService.pause,
      confirmation: UpdateDownloadStatus.paused,
      failureMessage: '当前下载暂时无法暂停，请稍后重试或等待下载完成',
    ),
  );

  Future<Result<void>> resume() => _exclusive(
    () => _taskAction(
      expected: UpdateTransferPhase.paused,
      action: _downloadService.resume,
      confirmation: UpdateDownloadStatus.downloading,
      failureMessage: '继续更新下载失败',
    ),
  );

  Future<Result<void>> _taskAction({
    required UpdateTransferPhase expected,
    required Future<bool> Function(String taskId) action,
    required UpdateDownloadStatus confirmation,
    required String failureMessage,
  }) async {
    final taskId = _transfer.taskId;
    if (_transfer.phase != expected || taskId == null) {
      return FailureResult(
        AppFailure(kind: FailureKind.conflict, message: failureMessage),
      );
    }
    final generation = _operationGeneration;
    final pending = PendingUpdateAction(taskId: taskId, target: confirmation);
    _pendingAction = pending;
    try {
      if (!await action(taskId)) {
        if (!_current(generation)) return _superseded();
        if (_transfer.phase == UpdateTransferPhase.readyToInstall ||
            _transfer.phase == UpdateTransferPhase.verifying ||
            (confirmation == UpdateDownloadStatus.paused &&
                _transfer.phase == UpdateTransferPhase.paused) ||
            (confirmation == UpdateDownloadStatus.downloading &&
                _transfer.phase == UpdateTransferPhase.downloading)) {
          return const Success<void>(null);
        }
        return FailureResult(
          AppFailure(kind: FailureKind.platform, message: failureMessage),
        );
      }
      final status = await pending.confirmed.timeout(_actionTimeout);
      if (!_current(generation)) return _superseded();
      if (status != confirmation && status != UpdateDownloadStatus.complete) {
        return const FailureResult(
          AppFailure(kind: FailureKind.platform, message: '更新下载状态已变化，请查看当前进度'),
        );
      }
      return const Success<void>(null);
    } on TimeoutException catch (error, stackTrace) {
      if (!_current(generation)) return _superseded();
      return _failure(
        FailureKind.timeout,
        '等待下载状态确认超时，请稍后重试',
        error,
        stackTrace,
      );
    } catch (error, stackTrace) {
      if (!_current(generation)) return _superseded();
      return _failure(FailureKind.platform, failureMessage, error, stackTrace);
    } finally {
      if (identical(_pendingAction, pending)) _pendingAction = null;
    }
  }

  Future<Result<void>> cancel() => _exclusive(_cancel);

  Future<Result<void>> _cancel() async {
    final taskId = _transfer.taskId;
    if (taskId == null || !_transfer.canCancel) {
      return const FailureResult(
        AppFailure(kind: FailureKind.conflict, message: '当前没有可取消的更新下载'),
      );
    }
    final generation = ++_operationGeneration;
    try {
      _eventTaskId = null;
      _downloadPlan = null;
      await _downloadService.remove(taskId, deleteFile: true);
      if (!_current(generation)) return _superseded();
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
      if (!_current(generation)) return _superseded();
      _failTransfer('取消更新下载失败，请重试');
      return _failure(FailureKind.storage, '取消更新下载失败', error, stackTrace);
    }
  }

  Future<Result<void>> install() => _exclusive(_install);

  Future<Result<void>> _install() async {
    final taskId = _transfer.taskId;
    if ((_transfer.phase != UpdateTransferPhase.readyToInstall &&
            _transfer.phase != UpdateTransferPhase.installerLaunched) ||
        taskId == null) {
      return const FailureResult(
        AppFailure(kind: FailureKind.conflict, message: '更新包尚未准备完成'),
      );
    }
    final generation = _operationGeneration;
    _setTransfer(
      _transfer.copyWith(
        phase: UpdateTransferPhase.awaitingPermission,
        clearError: true,
      ),
    );
    try {
      final permission = await _permissionService.ensureInstallPermission();
      if (!_current(generation)) return _superseded();
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
      final opened = await _downloadService.openFile(
        taskId,
        mimeType: _apkMimeType,
      );
      if (!_current(generation)) return _superseded();
      if (!opened) {
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
      if (!_current(generation)) return _superseded();
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
    _eventTaskId = request.taskId;
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
      requestedSource: UpdateDownloadSource.automatic,
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
    _pendingAction?.cancel();
    unawaited(_downloadSubscription?.cancel());
    _downloadService.dispose();
    super.dispose();
  }
}
