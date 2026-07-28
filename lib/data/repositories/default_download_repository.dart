import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/download_export_outcome.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/video_download_settings.dart';
import '../../domain/models/video_download_task.dart';
import '../services/download_export_service.dart';
import '../services/download_file_service.dart';
import '../services/download_settings_service.dart';
import '../services/download_task_service.dart';
import '../services/ffmpeg_download_service.dart';
import '../services/media_url_resolver.dart';
import 'download_repository.dart';

final class DefaultDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  DefaultDownloadRepository({
    DownloadTaskStore? taskStore,
    DownloadSettingsStore? settingsStore,
    DownloadFileStore? fileStore,
    VideoDownloadEngine? engine,
    DownloadExportService? exportService,
  }) : _taskStore = taskStore ?? SharedPreferencesDownloadTaskStore(),
       _settingsStore =
           settingsStore ?? SharedPreferencesDownloadSettingsStore(),
       _fileStore = fileStore ?? DownloadFileStore(),
       _engine = engine ?? FfmpegDownloadEngine(),
       _exportService = exportService ?? PlatformDownloadExportService();

  final DownloadTaskStore _taskStore;
  final DownloadSettingsStore _settingsStore;
  final DownloadFileStore _fileStore;
  final VideoDownloadEngine _engine;
  final DownloadExportService _exportService;
  final List<VideoDownloadTask> _tasks = <VideoDownloadTask>[];
  final Set<String> _runningTaskIds = <String>{};

  Future<void> _persistTail = Future<void>.value();
  Future<void> _settingsUpdateTail = Future<void>.value();
  Timer? _progressPersistTimer;
  Future<void>? _initializationFuture;
  bool _initialized = false;
  bool _pumping = false;
  int _maxConcurrentDownloads =
      VideoDownloadSettings.defaultMaxConcurrentDownloads;
  String? _initializationError;

  @override
  List<VideoDownloadTask> get tasks =>
      List<VideoDownloadTask>.unmodifiable(_tasks);

  @override
  bool get isInitialized => _initialized;

  @override
  String? get initializationError => _initializationError;

  @override
  int get maxConcurrentDownloads => _maxConcurrentDownloads;

  @override
  int get activeCount => _tasks.where((task) => task.isActive).length;

  @override
  int get queuedCount =>
      _tasks.where((task) => task.status == VideoDownloadStatus.queued).length;

  @override
  int get completedCount => _tasks
      .where((task) => task.status == VideoDownloadStatus.completed)
      .length;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final ongoingInitialization = _initializationFuture;
    if (ongoingInitialization != null) {
      return ongoingInitialization;
    }
    final initialization = _initialize();
    _initializationFuture = initialization;
    try {
      await initialization;
    } catch (_) {
      _initializationError = '下载任务初始化失败';
      notifyListeners();
      rethrow;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initialize() async {
    final storedTasks = await _taskStore.load();
    final settings = await _settingsStore.load();
    _maxConcurrentDownloads = settings.maxConcurrentDownloads;
    _tasks
      ..clear()
      ..addAll(storedTasks);

    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      if (task.status == VideoDownloadStatus.completed) {
        if (!await _fileStore.isValidCompletedFile(task.filePath)) {
          _tasks[index] = task.copyWith(
            status: VideoDownloadStatus.failed,
            errorMessage: '下载文件已丢失或为空',
          );
        }
      } else if (task.isActive) {
        await _fileStore.removeTemporary(task);
        _tasks[index] = task.copyWith(
          status: VideoDownloadStatus.queued,
          progress: 0,
          downloadedBytes: 0,
          clearDuration: true,
          clearBytesPerSecond: true,
          clearError: true,
        );
      }
    }
    _sortTasks();
    _initializationError = null;
    _initialized = true;
    await _persist();
    notifyListeners();
    unawaited(_pumpQueue());
  }

  @override
  Future<void> setMaxConcurrentDownloads(int value) async {
    await initialize();
    final normalized = VideoDownloadSettings.normalized(value);
    Future<void> update() async {
      if (normalized.maxConcurrentDownloads == _maxConcurrentDownloads) {
        return;
      }
      await _settingsStore.save(normalized);
      _maxConcurrentDownloads = normalized.maxConcurrentDownloads;
      notifyListeners();
      unawaited(_pumpQueue());
    }

    final updateFuture = _settingsUpdateTail.then(
      (_) => update(),
      onError: (_) => update(),
    );
    _settingsUpdateTail = updateFuture;
    await updateFuture;
  }

  @override
  Future<List<VideoDownloadTask>> enqueueAll(
    Iterable<VideoDownloadRequest> requests,
  ) async {
    await initialize();
    final results = <VideoDownloadTask>[];
    for (final request in requests) {
      results.add(_enqueue(request));
    }
    _sortTasks();
    await _persist();
    notifyListeners();
    unawaited(_pumpQueue());
    return results;
  }

  @override
  Future<List<VideoDownloadTask>> enqueueEpisodes({
    required SearchResult detail,
    required Iterable<int> episodeIndexes,
  }) async {
    final indexes = episodeIndexes.toList()..sort();
    final requests = <VideoDownloadRequest>[];
    for (final index in indexes) {
      if (index < 0 || index >= detail.episodes.length) {
        throw RangeError.index(index, detail.episodes, 'episodeIndexes');
      }
      final titles = detail.episodesTitles;
      final customTitle = index < titles.length ? titles[index].trim() : '';
      requests.add(
        VideoDownloadRequest(
          source: detail.source,
          contentId: detail.id,
          sourceName: detail.sourceName,
          title: detail.title,
          coverUrl: detail.poster,
          episodeIndex: index,
          episodeTitle: customTitle.isNotEmpty
              ? customTitle
              : detail.episodes.length == 1
              ? '正片'
              : '第 ${index + 1} 集',
          totalEpisodes: detail.episodes.length,
          mediaUrl: await MediaUrlResolver.resolve(detail.episodes[index]),
        ),
      );
    }
    return enqueueAll(requests);
  }

  VideoDownloadTask _enqueue(VideoDownloadRequest request) {
    final index = _tasks.indexWhere((task) => task.key == request.key);
    if (index < 0) {
      final task = VideoDownloadTask.fromRequest(request);
      _tasks.add(task);
      return task;
    }

    final existing = _tasks[index];
    if (existing.status == VideoDownloadStatus.failed ||
        existing.status == VideoDownloadStatus.cancelled) {
      final restarted = existing.copyWith(
        sourceName: request.sourceName,
        title: request.title,
        coverUrl: request.coverUrl,
        episodeTitle: request.episodeTitle,
        mediaUrl: request.mediaUrl,
        headers: Map<String, String>.unmodifiable(request.headers),
        status: VideoDownloadStatus.queued,
        progress: 0,
        downloadedBytes: 0,
        clearDuration: true,
        clearBytesPerSecond: true,
        clearFilePath: true,
        clearError: true,
        clearCompletedAt: true,
      );
      _tasks[index] = restarted;
      return restarted;
    }
    return existing;
  }

  @override
  Future<void> cancel(String taskId) async {
    final index = _indexOf(taskId);
    if (index < 0) {
      return;
    }
    final task = _tasks[index];
    if (task.status == VideoDownloadStatus.queued) {
      _tasks[index] = task.copyWith(status: VideoDownloadStatus.cancelled);
      await _fileStore.removeTemporary(task);
      await _persist();
      notifyListeners();
      return;
    }
    if (!task.isActive) {
      return;
    }
    _tasks[index] = task.copyWith(status: VideoDownloadStatus.cancelled);
    notifyListeners();
    await _persist();
    if (task.status == VideoDownloadStatus.probing ||
        task.status == VideoDownloadStatus.downloading ||
        task.status == VideoDownloadStatus.finalizing) {
      await _engine.cancel(taskId);
    }
  }

  @override
  Future<void> retry(String taskId) async {
    final index = _indexOf(taskId);
    if (index < 0 || !_tasks[index].canRetry) {
      return;
    }
    final task = _tasks[index];
    await _fileStore.removeTemporary(task);
    _tasks[index] = task.copyWith(
      status: VideoDownloadStatus.queued,
      progress: 0,
      downloadedBytes: 0,
      clearDuration: true,
      clearBytesPerSecond: true,
      clearFilePath: true,
      clearError: true,
      clearCompletedAt: true,
    );
    await _persist();
    notifyListeners();
    unawaited(_pumpQueue());
  }

  @override
  Future<void> delete(String taskId) async {
    final index = _indexOf(taskId);
    if (index < 0) {
      return;
    }
    final task = _tasks[index];
    if (task.isActive || task.status == VideoDownloadStatus.queued) {
      await cancel(taskId);
    }
    await _fileStore.removeTemporary(task);
    await _fileStore.deleteCompletedFile(task.filePath);
    _tasks.removeWhere((item) => item.id == taskId);
    await _persist();
    notifyListeners();
  }

  @override
  Future<DownloadExportOutcome> export(String taskId) async {
    await initialize();
    final index = _indexOf(taskId);
    if (index < 0) {
      throw StateError('下载任务不存在');
    }
    if (_tasks[index].status != VideoDownloadStatus.completed) {
      throw StateError('下载任务尚未完成');
    }
    final filePath = await _validCompletedPathAt(index);
    if (filePath == null) {
      throw const FileSystemException('下载文件已丢失或为空');
    }
    return _exportService.export(filePath);
  }

  @override
  Future<String?> completedPathFor({
    required String source,
    required String contentId,
    required int episodeIndex,
  }) async {
    await initialize();
    final key = VideoDownloadRequest.buildKey(
      source: source,
      contentId: contentId,
      episodeIndex: episodeIndex,
    );
    final index = _tasks.indexWhere(
      (task) => task.key == key && task.status == VideoDownloadStatus.completed,
    );
    if (index < 0) {
      return null;
    }
    return _validCompletedPathAt(index);
  }

  Future<String?> _validCompletedPathAt(int index) async {
    final task = _tasks[index];
    if (await _fileStore.isValidCompletedFile(task.filePath)) {
      return task.filePath;
    }
    _tasks[index] = task.copyWith(
      status: VideoDownloadStatus.failed,
      errorMessage: '下载文件已丢失或为空',
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> _pumpQueue() async {
    if (_pumping || !_initialized) {
      return;
    }
    _pumping = true;
    try {
      while (_runningTaskIds.length < _maxConcurrentDownloads) {
        final task = _tasks.cast<VideoDownloadTask?>().firstWhere(
          (item) =>
              item?.status == VideoDownloadStatus.queued &&
              !_runningTaskIds.contains(item?.id),
          orElse: () => null,
        );
        if (task == null) {
          break;
        }
        _runningTaskIds.add(task.id);
        unawaited(_runTaskSafely(task.id));
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _runTaskSafely(String taskId) async {
    try {
      await _runTask(taskId);
    } catch (_) {
      debugPrint('Video download task state persistence failed');
    } finally {
      _runningTaskIds.remove(taskId);
      unawaited(_pumpQueue());
    }
  }

  Future<void> _runTask(String taskId) async {
    var task = _taskById(taskId);
    if (task == null || task.status != VideoDownloadStatus.queued) {
      return;
    }
    try {
      await _fileStore.removeTemporary(task);
      task = _taskById(taskId);
      if (task == null || task.status != VideoDownloadStatus.queued) {
        return;
      }
      _replace(
        task.copyWith(
          status: VideoDownloadStatus.probing,
          progress: 0,
          downloadedBytes: 0,
          clearDuration: true,
          clearBytesPerSecond: true,
          clearError: true,
        ),
      );
      await _persist();
      notifyListeners();

      int? durationMs;
      var isLiveStream = false;
      try {
        final probe = await _engine.probe(
          taskId: taskId,
          mediaUrl: task.mediaUrl,
          headers: task.headers,
        );
        durationMs = probe.durationMs;
        isLiveStream = probe.isLiveStream;
      } catch (_) {
        durationMs = null;
      }
      if (isLiveStream) {
        throw const DownloadEngineException('直播流不支持下载');
      }

      task = _taskById(taskId);
      if (task == null || task.status == VideoDownloadStatus.cancelled) {
        return;
      }
      final paths = await _fileStore.pathsFor(task);
      _replace(
        task.copyWith(
          status: VideoDownloadStatus.downloading,
          durationMs: durationMs,
          clearDuration: durationMs == null,
          clearBytesPerSecond: true,
        ),
      );
      await _persist();
      notifyListeners();

      await _engine.download(
        taskId: taskId,
        mediaUrl: task.mediaUrl,
        headers: task.headers,
        outputPath: paths.temporaryPath,
        onProgress: (progress) {
          final current = _taskById(taskId);
          if (current == null ||
              current.status != VideoDownloadStatus.downloading) {
            return;
          }
          final fraction = current.durationMs == null
              ? 0.0
              : progress.processedTimeMs / current.durationMs!;
          _replace(
            current.copyWith(
              progress: fraction.clamp(0.0, 0.99),
              downloadedBytes: progress.downloadedBytes,
              bytesPerSecond: progress.bytesPerSecond,
            ),
          );
          notifyListeners();
          _scheduleProgressPersist();
        },
      );

      task = _taskById(taskId);
      if (task == null || task.status == VideoDownloadStatus.cancelled) {
        final temporaryFile = File(paths.temporaryPath);
        if (await temporaryFile.exists()) {
          await temporaryFile.delete();
        }
        return;
      }
      _replace(task.copyWith(status: VideoDownloadStatus.finalizing));
      await _persist();
      notifyListeners();

      await _engine.verify(taskId: taskId, filePath: paths.temporaryPath);
      task = _taskById(taskId);
      if (task == null || task.status == VideoDownloadStatus.cancelled) {
        return;
      }
      final finalPath = await _fileStore.finalize(task);
      final finalSize = await File(finalPath).length();
      task = _taskById(taskId);
      if (task == null || task.status == VideoDownloadStatus.cancelled) {
        await _fileStore.deleteCompletedFile(finalPath);
        return;
      }
      final completedAt = DateTime.now();
      _replace(
        task.copyWith(
          status: VideoDownloadStatus.completed,
          progress: 1,
          downloadedBytes: finalSize,
          filePath: finalPath,
          clearError: true,
          completedAt: completedAt,
        ),
      );
    } on DownloadEngineException catch (error) {
      await _markFailedUnlessCancelled(taskId, error.message);
    } on FileSystemException catch (error) {
      await _markFailedUnlessCancelled(
        taskId,
        error.osError?.message ?? error.message,
      );
    } catch (_) {
      await _markFailedUnlessCancelled(taskId, '下载过程中发生未知错误');
    } finally {
      final current = _taskById(taskId);
      if (current != null && current.status != VideoDownloadStatus.completed) {
        await _fileStore.removeTemporary(current);
      }
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _markFailedUnlessCancelled(String taskId, String message) async {
    final current = _taskById(taskId);
    if (current == null || current.status == VideoDownloadStatus.cancelled) {
      return;
    }
    _replace(
      current.copyWith(
        status: VideoDownloadStatus.failed,
        errorMessage: message,
      ),
    );
  }

  void _scheduleProgressPersist() {
    _progressPersistTimer ??= Timer(const Duration(seconds: 1), () {
      _progressPersistTimer = null;
      unawaited(_persist());
    });
  }

  int _indexOf(String taskId) => _tasks.indexWhere((task) => task.id == taskId);

  VideoDownloadTask? _taskById(String taskId) {
    final index = _indexOf(taskId);
    return index < 0 ? null : _tasks[index];
  }

  void _replace(VideoDownloadTask task) {
    final index = _indexOf(task.id);
    if (index >= 0) {
      _tasks[index] = task;
    }
  }

  void _sortTasks() {
    _tasks.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  Future<void> _persist() {
    final snapshot = List<VideoDownloadTask>.from(_tasks);
    _persistTail = _persistTail.then(
      (_) => _taskStore.save(snapshot),
      onError: (_) => _taskStore.save(snapshot),
    );
    return _persistTail;
  }

  @override
  void dispose() {
    _progressPersistTimer?.cancel();
    super.dispose();
  }
}
