import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_update_transfer.dart';
import 'update_download_service.dart';

/// `background_downloader` 的 Android 适配层。
///
/// 这里只转换插件任务、事件和持久记录；线路选择、完整性校验及安装状态由
/// Repository 层持有，避免插件回调直接改变产品状态。
final class BackgroundUpdateDownloadService implements UpdateDownloadService {
  BackgroundUpdateDownloadService({FileDownloader? downloader})
    : _downloader = downloader ?? FileDownloader();

  static const group = 'app-update';
  static const directory = 'updates';

  final FileDownloader _downloader;
  final StreamController<UpdateDownloadEvent> _updates =
      StreamController<UpdateDownloadEvent>.broadcast();
  final Map<String, DownloadTask> _tasks = <String, DownloadTask>{};
  StreamSubscription<TaskUpdate>? _subscription;
  bool _initialized = false;

  @override
  bool get supported => true;

  @override
  Stream<UpdateDownloadEvent> get updates => _updates.stream;

  @override
  Future<UpdateDownloadRecord?> initialize() async {
    if (!_initialized) {
      _subscription = _downloader.updates
          .where((update) => update.task.group == group)
          .listen(_handleUpdate);
      _downloader.configureNotificationForGroup(
        group,
        running: const TaskNotification(
          '正在下载 Selene 更新',
          '{displayName} · {progress}',
        ),
        complete: const TaskNotification('Selene 更新已下载', '返回应用完成校验并安装'),
        error: const TaskNotification('Selene 更新下载失败', '返回应用重试或切换下载线路'),
        paused: const TaskNotification('Selene 更新已暂停', '{displayName}'),
        canceled: const TaskNotification('Selene 更新已取消', '{displayName}'),
        progressBar: true,
        tapOpensFile: false,
      );
      await _downloader.configure(
        androidConfig: const <(String, dynamic)>[
          (Config.useExternalStorage, Config.never),
          (Config.useCacheDir, Config.never),
          (Config.requestTimeout, Duration(seconds: 20)),
          (Config.checkAvailableSpace, 100),
        ],
      );
      await _downloader.trackTasksInGroup(group);
      await _downloader.resumeFromBackground();
      _initialized = true;
      // 被系统终止的任务需要等待插件数据库恢复完成后再调度。
      unawaited(_rescheduleKilledTasks());
    }

    final records = await _downloader.database.allRecords(group: group);
    records.sort(
      (left, right) =>
          right.task.creationTime.compareTo(left.task.creationTime),
    );
    for (final record in records) {
      if (record.task case final DownloadTask task) {
        _tasks[task.taskId] = task;
        final request = _requestFromTask(task);
        if (request != null) {
          return UpdateDownloadRecord(
            request: request,
            status: _status(record.status),
            progress: record.progress.clamp(0, 1),
          );
        }
      }
    }
    return null;
  }

  Future<void> _rescheduleKilledTasks() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!_initialized) return;
    try {
      await _downloader.rescheduleKilledTasks();
    } catch (_) {
      // 初始化和当前任务恢复已完成；延迟重调度失败由后续任务状态反馈。
    }
  }

  @override
  Future<bool> enqueue(UpdateDownloadRequest request) async {
    final task = DownloadTask(
      taskId: request.taskId,
      url: request.uri.toString(),
      filename: request.asset.fileName,
      directory: directory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: group,
      updates: Updates.statusAndProgress,
      retries: request.retries,
      allowPause: true,
      priority: request.priority,
      displayName: 'Selene ${request.version}',
      metaData: jsonEncode(_metadata(request)),
    );
    _tasks[task.taskId] = task;
    return _downloader.enqueue(task);
  }

  @override
  Future<bool> pause(String taskId) async {
    final task = await _task(taskId);
    return task != null && await _downloader.pause(task);
  }

  @override
  Future<bool> resume(String taskId) async {
    final task = await _task(taskId);
    return task != null && await _downloader.resume(task);
  }

  @override
  Future<void> cancel(String taskId) async {
    await _downloader.cancelTaskWithId(taskId);
  }

  @override
  Future<String?> filePath(String taskId) async {
    final task = await _task(taskId);
    return task?.filePath();
  }

  @override
  Future<void> remove(String taskId, {required bool deleteFile}) async {
    await cancel(taskId);
    final path = await filePath(taskId);
    if (deleteFile && path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _downloader.database.deleteRecordWithId(taskId);
    _tasks.remove(taskId);
  }

  @override
  Future<bool> openFile(String taskId, {required String mimeType}) async {
    final task = await _task(taskId);
    return task != null &&
        await _downloader.openFile(task: task, mimeType: mimeType);
  }

  Future<DownloadTask?> _task(String taskId) async {
    final cached = _tasks[taskId];
    if (cached != null) return cached;
    final record = await _downloader.database.recordForId(taskId);
    final task = record?.task;
    if (task is DownloadTask) {
      _tasks[taskId] = task;
      return task;
    }
    return null;
  }

  void _handleUpdate(TaskUpdate update) {
    if (_updates.isClosed) return;
    final event = switch (update) {
      TaskProgressUpdate(
        :final task,
        :final progress,
        :final expectedFileSize,
      ) =>
        UpdateDownloadEvent(
          taskId: task.taskId,
          status: UpdateDownloadStatus.downloading,
          progress: progress.clamp(0, 1),
          downloadedBytes: expectedFileSize > 0
              ? (expectedFileSize * progress.clamp(0, 1)).round()
              : 0,
          totalBytes: expectedFileSize > 0 ? expectedFileSize : 0,
        ),
      TaskStatusUpdate(:final task, :final status, :final exception) =>
        UpdateDownloadEvent(
          taskId: task.taskId,
          status: _status(status),
          progress: status == TaskStatus.complete ? 1 : 0,
          errorMessage: exception?.description,
        ),
    };
    _updates.add(event);
  }

  static UpdateDownloadStatus _status(TaskStatus status) => switch (status) {
    TaskStatus.enqueued ||
    TaskStatus.waitingToRetry => UpdateDownloadStatus.queued,
    TaskStatus.running => UpdateDownloadStatus.downloading,
    TaskStatus.paused => UpdateDownloadStatus.paused,
    TaskStatus.complete => UpdateDownloadStatus.complete,
    TaskStatus.notFound => UpdateDownloadStatus.notFound,
    TaskStatus.failed => UpdateDownloadStatus.failed,
    TaskStatus.canceled => UpdateDownloadStatus.cancelled,
  };

  /// 元数据只保存恢复任务所需的公开 Release 信息，不保存认证头或私有数据。
  static Map<String, Object> _metadata(UpdateDownloadRequest request) =>
      <String, Object>{
        'schema': 2,
        'version': request.version,
        'fileName': request.asset.fileName,
        'downloadUri': request.asset.downloadUri.toString(),
        'size': request.asset.size,
        'sha256': request.asset.sha256,
        'architecture': request.asset.architecture.name,
        'source': request.source.name,
        'uri': request.uri.toString(),
        'retries': request.retries,
        'priority': request.priority,
      };

  static UpdateDownloadRequest? _requestFromTask(DownloadTask task) {
    try {
      final metadata = jsonDecode(task.metaData);
      if (metadata is! Map<String, dynamic> || metadata['schema'] != 2) {
        return null;
      }
      final architecture = AndroidArchitecture.values.byName(
        metadata['architecture'] as String,
      );
      final source = UpdateDownloadSource.values.byName(
        metadata['source'] as String,
      );
      final asset = AppReleaseAsset(
        fileName: metadata['fileName'] as String,
        downloadUri: Uri.parse(metadata['downloadUri'] as String),
        size: metadata['size'] as int,
        sha256: metadata['sha256'] as String,
        architecture: architecture,
      );
      return UpdateDownloadRequest(
        taskId: task.taskId,
        version: metadata['version'] as String,
        asset: asset,
        source: source,
        uri: Uri.parse(metadata['uri'] as String),
        retries: metadata['retries'] as int,
        priority: metadata['priority'] as int,
      );
    } catch (_) {
      // 来自旧版本或损坏记录的元数据不能进入可信更新状态机。
      return null;
    }
  }

  @override
  void dispose() {
    _initialized = false;
    unawaited(_subscription?.cancel());
    unawaited(_updates.close());
  }
}
