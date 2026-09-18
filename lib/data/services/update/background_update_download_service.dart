import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_update_transfer.dart';
import 'background_update_event_mapper.dart';
import 'update_download_service.dart';
import 'update_resume_capability_store.dart';

/// `background_downloader` 的 Android 适配层。
///
/// 这里只转换插件任务、事件和持久记录；线路选择、完整性校验及安装状态由
/// Repository 层持有，避免插件回调直接改变产品状态。
final class BackgroundUpdateDownloadService implements UpdateDownloadService {
  BackgroundUpdateDownloadService({
    FileDownloader? downloader,
    UpdateResumeCapabilityStore? capabilityStore,
  }) : _downloader = downloader ?? FileDownloader(),
       _capabilityStore =
           capabilityStore ?? SharedPreferencesUpdateResumeCapabilityStore();

  static const group = 'app-update';
  static const directory = 'updates';

  final FileDownloader _downloader;
  final UpdateResumeCapabilityStore _capabilityStore;
  final StreamController<UpdateDownloadEvent> _updates =
      StreamController<UpdateDownloadEvent>.broadcast();
  final Map<String, DownloadTask> _tasks = <String, DownloadTask>{};
  // 只有本次 enqueue/resume 的任务，插件才持有可用于判断“不支持”的记录。
  final Set<String> _sessionTasks = <String>{};
  final Map<String, Object> _capabilityWatches = <String, Object>{};
  Future<void> _capabilityWrites = Future<void>.value();
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
        error: const TaskNotification('Selene 更新下载失败', '返回应用重试或使用浏览器下载'),
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
            status: mapBackgroundStatus(record.status),
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
      final (rescheduled, _) = await _downloader.rescheduleKilledTasks();
      for (final task in rescheduled) {
        if (!_initialized) return;
        if (task is! DownloadTask || task.group != group) continue;
        // 重新入队建立了新连接，旧能力不能继续用于冷恢复。
        _sessionTasks.add(task.taskId);
        await _forgetCapability(task.taskId);
        if (!_initialized) return;
        _watchCapability(task);
      }
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
    await _forgetCapability(task.taskId);
    _tasks[task.taskId] = task;
    final enqueued = await _downloader.enqueue(task);
    if (enqueued) _watchCapability(task);
    return enqueued;
  }

  @override
  Future<bool> pause(String taskId) async {
    if (_updates.isClosed) return false;
    final task = await _task(taskId);
    if (task == null) return false;
    var resumable = await _downloader
        .taskCanResume(task)
        .timeout(const Duration(seconds: 10));
    if (_updates.isClosed || !_tasks.containsKey(taskId)) return false;
    if (!resumable && !_sessionTasks.contains(taskId)) {
      // 插件在进程重建后会丢失能力 Completer，只能用之前真实确认的记录补充。
      // 不重新探测服务器：新的响应不能代表正在运行的原生任务能够安全暂停。
      await _capabilityWrites;
      resumable =
          await _capabilityStore.read(
            taskId,
            retriesRemaining: task.retriesRemaining,
          ) ==
          true;
    }
    return !_updates.isClosed &&
        _tasks.containsKey(taskId) &&
        resumable &&
        await _downloader.pause(task);
  }

  @override
  Future<bool> resume(String taskId) async {
    final task = await _task(taskId);
    if (task == null) return false;
    await _forgetCapability(taskId);
    final resumed = await _downloader.resume(task);
    if (resumed) _watchCapability(task);
    return resumed;
  }

  @override
  Future<void> cancel(String taskId) async {
    _sessionTasks.remove(taskId);
    try {
      await _forgetCapability(taskId);
    } finally {
      // 辅助记录清理失败也不能阻止用户取消实际下载。
      await _downloader.cancelTaskWithId(taskId);
    }
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
    _sessionTasks.remove(taskId);
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
    if (update.task case final DownloadTask task) {
      // 自动重试会改变剩余次数，能力记录只能用于同一次连接尝试。
      _tasks[task.taskId] = task;
      if (update is TaskStatusUpdate &&
          update.status == TaskStatus.running &&
          _sessionTasks.contains(task.taskId)) {
        _watchCapability(task);
      }
    }
    final event = mapBackgroundUpdate(update);
    if (event != null) _updates.add(event);
  }

  void _watchCapability(DownloadTask task) {
    if (_updates.isClosed) return;
    _sessionTasks.add(task.taskId);
    final token = Object();
    _capabilityWatches[task.taskId] = token;
    unawaited(_saveCapability(task, token));
  }

  Future<void> _saveCapability(DownloadTask task, Object token) async {
    final retriesRemaining = task.retriesRemaining;
    try {
      final supported = await _downloader.taskCanResume(task);
      if (_updates.isClosed || _capabilityWatches[task.taskId] != token) return;
      await _writeCapability(
        () => _capabilityStore.write(
          task.taskId,
          supported,
          retriesRemaining: retriesRemaining,
        ),
      );
    } catch (_) {
      // 记录失败不终止正在下载的任务；冷恢复时无记录会保守地拒绝暂停。
    }
  }

  Future<void> _forgetCapability(String taskId) {
    _capabilityWatches.remove(taskId);
    return _writeCapability(() => _capabilityStore.remove(taskId));
  }

  Future<void> _writeCapability(Future<void> Function() write) {
    final operation = _capabilityWrites.then((_) => write());
    // 写入与删除按序执行，避免取消后晚到的写入重新留下旧记录。
    _capabilityWrites = operation.catchError((Object _) {});
    return operation;
  }

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
    _capabilityWatches.clear();
    unawaited(_subscription?.cancel());
    unawaited(_updates.close());
  }
}
