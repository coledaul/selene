import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/default_download_repository.dart';
import 'package:selene/data/services/download_export_service.dart';
import 'package:selene/data/services/download_file_service.dart';
import 'package:selene/data/services/download_settings_service.dart';
import 'package:selene/data/services/download_task_service.dart';
import 'package:selene/data/services/ffmpeg_download_service.dart';
import 'package:selene/domain/models/download_export_outcome.dart';
import 'package:selene/domain/models/video_download_settings.dart';
import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/downloads/widgets/download_manager_screen.dart';
import 'package:selene/ui/downloads/view_models/download_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoDownloadTask', () {
    test('序列化后保留任务身份与下载状态', () {
      final task = VideoDownloadTask.fromRequest(_request()).copyWith(
        status: VideoDownloadStatus.downloading,
        progress: 0.42,
        downloadedBytes: 1024,
        durationMs: 90000,
        bytesPerSecond: 2048,
      );

      final restored = VideoDownloadTask.fromJson(task.toJson());

      expect(restored.key, task.key);
      expect(restored.status, VideoDownloadStatus.downloading);
      expect(restored.progress, 0.42);
      expect(restored.downloadedBytes, 1024);
      expect(restored.durationMs, 90000);
      expect(restored.bytesPerSecond, 2048);
      expect(restored.toJson(), isNot(contains('speed')));
    });
  });

  group('DownloadFileStore', () {
    test('清理跨平台非法文件名并限制长度', () {
      final sanitized = DownloadFileStore.sanitizeFileName(
        '${'a' * 70}/:*?"<>|',
        fallback: 'video',
      );

      expect(sanitized.length, 64);
      expect(sanitized, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
    });
  });

  group('DownloadSettingsStore', () {
    test('默认同时下载三个任务并修正非法持久化值', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesDownloadSettingsStore();

      expect(
        (await store.load()).maxConcurrentDownloads,
        VideoDownloadSettings.defaultMaxConcurrentDownloads,
      );

      SharedPreferences.setMockInitialValues(<String, Object>{
        'video_download_max_concurrent_downloads': 99,
      });
      expect(
        (await store.load()).maxConcurrentDownloads,
        VideoDownloadSettings.maxConcurrentDownloadsLimit,
      );
    });

    test('保存后可恢复用户设置', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesDownloadSettingsStore();

      await store.save(const VideoDownloadSettings(maxConcurrentDownloads: 5));

      expect((await store.load()).maxConcurrentDownloads, 5);
    });
  });

  group('FfmpegDownloadEngine', () {
    test('根据已写入字节和单调耗时计算真实吞吐速度', () {
      expect(
        calculateDownloadBytesPerSecond(
          downloadedBytes: 4 * 1024 * 1024,
          elapsed: const Duration(seconds: 2),
        ),
        2 * 1024 * 1024,
      );
      expect(
        calculateDownloadBytesPerSecond(
          downloadedBytes: 1024,
          elapsed: Duration.zero,
        ),
        isNull,
      );
    });

    test('拒绝非 HTTP(S) 媒体地址且不会启动原生会话', () async {
      final engine = FfmpegDownloadEngine();

      await expectLater(
        engine.probe(
          taskId: 'invalid-url',
          mediaUrl: 'file:///private/video.mkv',
          headers: const {},
        ),
        throwsA(
          isA<DownloadEngineException>().having(
            (error) => error.message,
            'message',
            contains('HTTP'),
          ),
        ),
      );
    });
  });

  group('DefaultDownloadRepository', () {
    late Directory temporaryDirectory;
    late _MemoryTaskStore taskStore;
    late _MemorySettingsStore settingsStore;
    late _FakeDownloadEngine engine;
    late _FakeDownloadExportService exportService;
    late DefaultDownloadRepository manager;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'selene-download-test-',
      );
      taskStore = _MemoryTaskStore();
      settingsStore = _MemorySettingsStore();
      engine = _FakeDownloadEngine();
      exportService = _FakeDownloadExportService();
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: engine,
        exportService: exportService,
      );
      await manager.initialize();
    });

    tearDown(() async {
      manager.dispose();
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('相同来源、内容和集数只创建一个任务', () async {
      await manager.enqueueAll(<VideoDownloadRequest>[_request(), _request()]);

      await _waitUntil(() => manager.completedCount == 1);

      expect(manager.tasks, hasLength(1));
      expect(engine.downloadCount, 1);
      expect(manager.tasks.single.filePath, endsWith('.mkv'));
      expect(await File(manager.tasks.single.filePath!).exists(), isTrue);
    });

    test('仅把有效完成文件交给导出 Service', () async {
      await manager.enqueueAll(<VideoDownloadRequest>[_request()]);
      await _waitUntil(() => manager.completedCount == 1);
      final task = manager.tasks.single;

      final outcome = await manager.export(task.id);

      expect(outcome, DownloadExportOutcome.exported);
      expect(exportService.sourceFilePaths, <String>[task.filePath!]);
      expect(manager.tasks.single.filePath, task.filePath);
    });

    test('用户取消导出时保留取消结果和私有完成文件', () async {
      exportService.outcome = DownloadExportOutcome.cancelled;
      await manager.enqueueAll(<VideoDownloadRequest>[_request()]);
      await _waitUntil(() => manager.completedCount == 1);
      final task = manager.tasks.single;

      final outcome = await manager.export(task.id);

      expect(outcome, DownloadExportOutcome.cancelled);
      expect(await File(task.filePath!).exists(), isTrue);
      expect(manager.tasks.single.status, VideoDownloadStatus.completed);
    });

    test('非完成任务不能导出', () async {
      manager.dispose();
      taskStore.stored = <VideoDownloadTask>[
        VideoDownloadTask.fromRequest(
          _request(),
        ).copyWith(status: VideoDownloadStatus.cancelled),
      ];
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: engine,
        exportService: exportService,
      );
      await manager.initialize();

      await expectLater(
        manager.export(manager.tasks.single.id),
        throwsStateError,
      );
      expect(exportService.sourceFilePaths, isEmpty);
    });

    test('导出前发现完成文件丢失会修复任务状态并明确失败', () async {
      await manager.enqueueAll(<VideoDownloadRequest>[_request()]);
      await _waitUntil(() => manager.completedCount == 1);
      final task = manager.tasks.single;
      await File(task.filePath!).delete();

      await expectLater(
        manager.export(task.id),
        throwsA(isA<FileSystemException>()),
      );

      expect(manager.tasks.single.status, VideoDownloadStatus.failed);
      expect(manager.tasks.single.errorMessage, '下载文件已丢失或为空');
      expect(exportService.sourceFilePaths, isEmpty);
    });

    test('默认同时启动三个独立下载任务', () async {
      manager.dispose();
      final controlledEngine = _ControlledDownloadEngine();
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: controlledEngine,
      );
      await manager.initialize();

      await manager.enqueueAll(
        List<VideoDownloadRequest>.generate(5, _requestForEpisode),
      );
      await _waitUntil(() => controlledEngine.startedTaskIds.isNotEmpty);

      expect(controlledEngine.startedTaskIds, hasLength(3));
      expect(controlledEngine.maxActiveCount, 3);
      expect(manager.queuedCount, 2);
      expect(
        controlledEngine.startCounts.values.every((count) => count == 1),
        isTrue,
      );

      controlledEngine.completeAll();
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 5);
      controlledEngine.completeAll();
      await _waitUntil(() => manager.completedCount == 5);
    });

    test('任务完成或失败后立即补充等待任务', () async {
      manager.dispose();
      final controlledEngine = _ControlledDownloadEngine();
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: controlledEngine,
      );
      await manager.initialize();
      await manager.enqueueAll(
        List<VideoDownloadRequest>.generate(5, _requestForEpisode),
      );
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 3);

      final firstTaskId = controlledEngine.activeTaskIds.first;
      controlledEngine.complete(firstTaskId);
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 4);
      expect(controlledEngine.activeCount, 3);

      final secondTaskId = controlledEngine.activeTaskIds.first;
      controlledEngine.fail(secondTaskId);
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 5);
      expect(controlledEngine.activeCount, 3);

      controlledEngine.completeAll();
      await _waitUntil(() => manager.activeCount == 0);
      expect(
        manager.tasks.where(
          (task) => task.status == VideoDownloadStatus.failed,
        ),
        hasLength(1),
      );
    });

    test('取消运行任务后只停止该任务并立即补位', () async {
      manager.dispose();
      final controlledEngine = _ControlledDownloadEngine();
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: controlledEngine,
      );
      await manager.initialize();
      await manager.enqueueAll(
        List<VideoDownloadRequest>.generate(4, _requestForEpisode),
      );
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 3);
      final cancelledTaskId = controlledEngine.activeTaskIds.first;

      await manager.cancel(cancelledTaskId);
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 4);

      expect(controlledEngine.activeCount, 3);
      expect(
        manager.tasks.singleWhere((task) => task.id == cancelledTaskId).status,
        VideoDownloadStatus.cancelled,
      );
      expect(
        controlledEngine.startCounts.values.every((count) => count == 1),
        isTrue,
      );

      controlledEngine.completeAll();
      await _waitUntil(() => manager.activeCount == 0);
      expect(manager.completedCount, 3);
    });

    test('取消媒体探测任务后立即释放并发槽位', () async {
      manager.dispose();
      settingsStore.stored = const VideoDownloadSettings(
        maxConcurrentDownloads: 1,
      );
      final controlledEngine = _ControlledProbeDownloadEngine();
      addTearDown(controlledEngine.completeAllProbes);
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: controlledEngine,
      );
      await manager.initialize();
      await manager.enqueueAll(
        List<VideoDownloadRequest>.generate(2, _requestForEpisode),
      );
      await _waitUntil(() => controlledEngine.probeCount == 1);
      final probingTask = manager.tasks.singleWhere(
        (task) => task.status == VideoDownloadStatus.probing,
      );

      await manager.cancel(probingTask.id);

      expect(controlledEngine.cancelledTaskIds, contains(probingTask.id));
      await _waitUntil(() => controlledEngine.probeCount == 2);
      controlledEngine.completeAllProbes();
      await _waitUntil(() => manager.activeCount == 0);
    });

    test('校验整理阶段取消不会被覆盖为已完成', () async {
      manager.dispose();
      settingsStore.stored = const VideoDownloadSettings(
        maxConcurrentDownloads: 1,
      );
      final controlledEngine = _ControlledFinalizeDownloadEngine();
      addTearDown(controlledEngine.completeFirstVerification);
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: controlledEngine,
      );
      await manager.initialize();
      await manager.enqueueAll(
        List<VideoDownloadRequest>.generate(2, _requestForEpisode),
      );
      await _waitUntil(
        () => manager.tasks.any(
          (task) => task.status == VideoDownloadStatus.finalizing,
        ),
      );
      final finalizingTask = manager.tasks.singleWhere(
        (task) => task.status == VideoDownloadStatus.finalizing,
      );

      await manager.cancel(finalizingTask.id);

      expect(controlledEngine.cancelledTaskIds, contains(finalizingTask.id));
      await _waitUntil(() => manager.completedCount == 1);

      final cancelledTask = manager.tasks.singleWhere(
        (task) => task.id == finalizingTask.id,
      );
      expect(cancelledTask.status, VideoDownloadStatus.cancelled);
      expect(cancelledTask.filePath, isNull);
      expect(
        manager.tasks.where(
          (task) => task.status == VideoDownloadStatus.completed,
        ),
        hasLength(1),
      );
    });

    test('调高并发数立即补位，调低时不取消正在下载的任务', () async {
      manager.dispose();
      settingsStore.stored = const VideoDownloadSettings(
        maxConcurrentDownloads: 1,
      );
      final controlledEngine = _ControlledDownloadEngine();
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: controlledEngine,
      );
      await manager.initialize();
      await manager.enqueueAll(
        List<VideoDownloadRequest>.generate(4, _requestForEpisode),
      );
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 1);

      await manager.setMaxConcurrentDownloads(3);
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 3);
      expect(controlledEngine.activeCount, 3);

      await manager.setMaxConcurrentDownloads(1);
      expect(controlledEngine.activeCount, 3);
      final runningIds = controlledEngine.activeTaskIds.toList();
      controlledEngine.complete(runningIds[0]);
      controlledEngine.complete(runningIds[1]);
      await _waitUntil(() => controlledEngine.activeCount == 1);
      expect(controlledEngine.startedTaskIds, hasLength(3));

      controlledEngine.complete(runningIds[2]);
      await _waitUntil(() => controlledEngine.startedTaskIds.length == 4);
      expect(controlledEngine.activeCount, 1);

      controlledEngine.completeAll();
      await _waitUntil(() => manager.completedCount == 4);
    });

    test('并发设置保存失败时保持原值', () async {
      manager.dispose();
      final failingSettingsStore = _MemorySettingsStore()..failSave = true;
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: failingSettingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: engine,
      );
      await manager.initialize();

      await expectLater(manager.setMaxConcurrentDownloads(5), throwsStateError);

      expect(
        manager.maxConcurrentDownloads,
        VideoDownloadSettings.defaultMaxConcurrentDownloads,
      );
    });

    test('修正超出允许范围的并发设置', () async {
      await manager.setMaxConcurrentDownloads(0);
      expect(
        manager.maxConcurrentDownloads,
        VideoDownloadSettings.minConcurrentDownloads,
      );

      await manager.setMaxConcurrentDownloads(99);
      expect(
        manager.maxConcurrentDownloads,
        VideoDownloadSettings.maxConcurrentDownloadsLimit,
      );
    });

    test('快速连续修改并发数时按调用顺序保存', () async {
      manager.dispose();
      final delayedSettingsStore = _DelayedSettingsStore();
      addTearDown(delayedSettingsStore.completeAll);
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: delayedSettingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: engine,
      );
      await manager.initialize();

      final updateToFive = manager.setMaxConcurrentDownloads(5);
      final updateToOne = manager.setMaxConcurrentDownloads(1);
      await _waitUntil(() => delayedSettingsStore.pendingSaveCount == 1);
      delayedSettingsStore.completeSaveAt(0);
      await updateToFive;
      await _waitUntil(() => delayedSettingsStore.pendingSaveCount == 2);
      delayedSettingsStore.completeSaveAt(1);
      await updateToOne;

      expect(manager.maxConcurrentDownloads, 1);
      expect(delayedSettingsStore.stored.maxConcurrentDownloads, 1);
    });

    test('失败任务可重试并完成', () async {
      engine.failNextDownload = true;
      await manager.enqueueAll(<VideoDownloadRequest>[_request()]);
      await _waitUntil(
        () => manager.tasks.single.status == VideoDownloadStatus.failed,
      );

      await manager.retry(manager.tasks.single.id);
      await _waitUntil(() => manager.completedCount == 1);

      expect(engine.downloadCount, 2);
      expect(manager.tasks.single.errorMessage, isNull);
    });

    test('应用异常退出遗留的活动任务会清理临时文件并恢复下载', () async {
      manager.dispose();
      final interruptedTask = VideoDownloadTask.fromRequest(_request())
          .copyWith(
            status: VideoDownloadStatus.downloading,
            progress: 0.6,
            downloadedBytes: 1024,
          );
      taskStore.stored = <VideoDownloadTask>[interruptedTask];
      final fileStore = DownloadFileStore(
        rootDirectoryProvider: () async => temporaryDirectory,
      );
      final paths = await fileStore.pathsFor(interruptedTask);
      await File(paths.temporaryPath).writeAsString('partial');
      manager = DefaultDownloadRepository(
        taskStore: taskStore,
        settingsStore: settingsStore,
        fileStore: fileStore,
        engine: engine,
      );

      await manager.initialize();
      await _waitUntil(() => manager.completedCount == 1);

      expect(manager.tasks.single.progress, 1);
      expect(await File(paths.temporaryPath).exists(), isFalse);
      expect(await File(manager.tasks.single.filePath!).exists(), isTrue);
    });

    test('完成任务删除时同时删除任务记录和本地文件', () async {
      await manager.enqueueAll(<VideoDownloadRequest>[_request()]);
      await _waitUntil(() => manager.completedCount == 1);
      final task = manager.tasks.single;
      final file = File(task.filePath!);
      expect(await file.exists(), isTrue);

      await manager.delete(task.id);

      expect(manager.tasks, isEmpty);
      expect(await file.exists(), isFalse);
    });

    test('初始化失败可见并可重试', () async {
      manager.dispose();
      final failOnceStore = _FailOnceTaskStore();
      manager = DefaultDownloadRepository(
        taskStore: failOnceStore,
        settingsStore: settingsStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: engine,
      );

      await expectLater(manager.initialize(), throwsStateError);
      expect(manager.initializationError, isNotNull);

      await manager.initialize();
      expect(manager.isInitialized, isTrue);
      expect(manager.initializationError, isNull);
      expect(failOnceStore.loadCount, 2);
    });

    test('HLS 直播流会明确失败且不会启动下载', () async {
      engine.isLiveStream = true;

      await manager.enqueueAll(<VideoDownloadRequest>[_request()]);
      await _waitUntil(
        () => manager.tasks.single.status == VideoDownloadStatus.failed,
      );

      expect(manager.tasks.single.errorMessage, contains('直播流'));
      expect(engine.downloadCount, 0);
    });
  });

  testWidgets('下载管理可修改同时下载任务数', (tester) async {
    final manager = DefaultDownloadRepository(
      taskStore: _MemoryTaskStore(),
      settingsStore: _MemorySettingsStore(),
      engine: _FakeDownloadEngine(),
    );
    await manager.initialize();
    addTearDown(manager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DownloadManagerScreen(
          viewModelFactory: () => DownloadViewModel(repository: manager),
        ),
      ),
    );

    await tester.tap(find.byTooltip('下载设置'));
    await tester.pumpAndSettle();
    expect(find.text('同时下载任务数'), findsOneWidget);
    expect(find.text('3 个（默认）'), findsOneWidget);

    await tester.tap(find.text('5 个'));
    await tester.pumpAndSettle();

    expect(manager.maxConcurrentDownloads, 5);
    expect(find.text('同时下载任务数'), findsNothing);
  });
}

VideoDownloadRequest _request() => const VideoDownloadRequest(
  source: 'source-a',
  contentId: 'video-1',
  sourceName: '测试源',
  title: '测试视频',
  coverUrl: '',
  episodeIndex: 0,
  episodeTitle: '第 1 集',
  totalEpisodes: 1,
  mediaUrl: 'https://example.com/video.m3u8',
);

VideoDownloadRequest _requestForEpisode(int index) => VideoDownloadRequest(
  source: 'source-a',
  contentId: 'video-1',
  sourceName: '测试源',
  title: '测试视频',
  coverUrl: '',
  episodeIndex: index,
  episodeTitle: '第 ${index + 1} 集',
  totalEpisodes: 5,
  mediaUrl: 'https://example.com/video-$index.m3u8',
);

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('等待下载状态超时');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _MemoryTaskStore implements DownloadTaskStore {
  List<VideoDownloadTask> stored = <VideoDownloadTask>[];

  @override
  Future<List<VideoDownloadTask>> load() async =>
      List<VideoDownloadTask>.from(stored);

  @override
  Future<void> save(List<VideoDownloadTask> tasks) async {
    stored = List<VideoDownloadTask>.from(tasks);
  }
}

class _MemorySettingsStore implements DownloadSettingsStore {
  VideoDownloadSettings stored = const VideoDownloadSettings();
  bool failSave = false;

  @override
  Future<VideoDownloadSettings> load() async => stored;

  @override
  Future<void> save(VideoDownloadSettings settings) async {
    if (failSave) {
      throw StateError('模拟下载设置保存失败');
    }
    stored = settings;
  }
}

class _DelayedSettingsStore implements DownloadSettingsStore {
  VideoDownloadSettings stored = const VideoDownloadSettings();
  final List<({VideoDownloadSettings settings, Completer<void> completion})>
  _pendingSaves = [];

  int get pendingSaveCount => _pendingSaves.length;

  @override
  Future<VideoDownloadSettings> load() async => stored;

  @override
  Future<void> save(VideoDownloadSettings settings) async {
    final completion = Completer<void>();
    _pendingSaves.add((settings: settings, completion: completion));
    await completion.future;
    stored = settings;
  }

  void completeSaveAt(int index) {
    final pending = _pendingSaves[index];
    if (!pending.completion.isCompleted) {
      pending.completion.complete();
    }
  }

  void completeAll() {
    for (final pending in _pendingSaves) {
      if (!pending.completion.isCompleted) {
        pending.completion.complete();
      }
    }
  }
}

class _FailOnceTaskStore extends _MemoryTaskStore {
  int loadCount = 0;

  @override
  Future<List<VideoDownloadTask>> load() async {
    loadCount++;
    if (loadCount == 1) {
      throw StateError('模拟初始化失败');
    }
    return super.load();
  }
}

class _FakeDownloadEngine implements VideoDownloadEngine {
  int downloadCount = 0;
  bool failNextDownload = false;
  bool isLiveStream = false;

  @override
  Future<DownloadProbeResult> probe({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
  }) async {
    return DownloadProbeResult(
      durationMs: isLiveStream ? null : 1000,
      isLiveStream: isLiveStream,
    );
  }

  @override
  Future<void> download({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
    required String outputPath,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    downloadCount++;
    if (failNextDownload) {
      failNextDownload = false;
      throw const DownloadEngineException('模拟下载失败');
    }
    onProgress(
      const DownloadProgress(
        processedTimeMs: 500,
        downloadedBytes: 4,
        bytesPerSecond: 1,
      ),
    );
    await File(outputPath).writeAsBytes(<int>[0, 1, 2, 3], flush: true);
  }

  @override
  Future<void> verify({
    required String taskId,
    required String filePath,
  }) async {
    if (!await File(filePath).exists()) {
      throw const DownloadEngineException('测试文件不存在');
    }
  }

  @override
  Future<void> cancel(String taskId) async {}
}

class _FakeDownloadExportService implements DownloadExportService {
  DownloadExportOutcome outcome = DownloadExportOutcome.exported;
  final List<String> sourceFilePaths = <String>[];

  @override
  Future<DownloadExportOutcome> export(String sourceFilePath) async {
    sourceFilePaths.add(sourceFilePath);
    return outcome;
  }
}

class _ControlledDownloadEngine implements VideoDownloadEngine {
  final Set<String> startedTaskIds = <String>{};
  final Map<String, int> startCounts = <String, int>{};
  final Map<String, Completer<void>> _completions = <String, Completer<void>>{};
  int activeCount = 0;
  int maxActiveCount = 0;

  Set<String> get activeTaskIds => Set<String>.unmodifiable(_completions.keys);

  @override
  Future<DownloadProbeResult> probe({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
  }) async => const DownloadProbeResult(durationMs: 1000, isLiveStream: false);

  @override
  Future<void> download({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
    required String outputPath,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    final completion = Completer<void>();
    _completions[taskId] = completion;
    startedTaskIds.add(taskId);
    startCounts.update(taskId, (count) => count + 1, ifAbsent: () => 1);
    activeCount++;
    if (activeCount > maxActiveCount) {
      maxActiveCount = activeCount;
    }
    try {
      await completion.future;
      await File(outputPath).writeAsBytes(<int>[0, 1, 2, 3], flush: true);
    } finally {
      activeCount--;
      _completions.remove(taskId);
    }
  }

  void completeAll() {
    for (final completion in _completions.values.toList(growable: false)) {
      if (!completion.isCompleted) {
        completion.complete();
      }
    }
  }

  void complete(String taskId) {
    final completion = _completions[taskId];
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  void fail(String taskId) {
    final completion = _completions[taskId];
    if (completion != null && !completion.isCompleted) {
      completion.completeError(const DownloadEngineException('模拟下载失败'));
    }
  }

  @override
  Future<void> verify({
    required String taskId,
    required String filePath,
  }) async {
    if (!await File(filePath).exists()) {
      throw const DownloadEngineException('测试文件不存在');
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    final completion = _completions[taskId];
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }
}

class _ControlledProbeDownloadEngine implements VideoDownloadEngine {
  final List<Completer<void>> _probes = <Completer<void>>[];
  final Set<String> cancelledTaskIds = <String>{};

  int get probeCount => _probes.length;

  @override
  Future<DownloadProbeResult> probe({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
  }) async {
    final completion = Completer<void>();
    _probes.add(completion);
    await completion.future;
    return const DownloadProbeResult(durationMs: 1000, isLiveStream: false);
  }

  @override
  Future<void> download({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
    required String outputPath,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    throw const DownloadEngineException('测试不应进入下载阶段');
  }

  void completeAllProbes() {
    for (final completion in _probes) {
      if (!completion.isCompleted) {
        completion.complete();
      }
    }
  }

  @override
  Future<void> verify({
    required String taskId,
    required String filePath,
  }) async {}

  @override
  Future<void> cancel(String taskId) async {
    cancelledTaskIds.add(taskId);
    for (final completion in _probes) {
      if (!completion.isCompleted) {
        completion.complete();
        break;
      }
    }
  }
}

class _ControlledFinalizeDownloadEngine implements VideoDownloadEngine {
  final Completer<void> _firstVerification = Completer<void>();
  final Set<String> cancelledTaskIds = <String>{};
  int _verificationCount = 0;

  @override
  Future<DownloadProbeResult> probe({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
  }) async => const DownloadProbeResult(durationMs: 1000, isLiveStream: false);

  @override
  Future<void> download({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
    required String outputPath,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    await File(outputPath).writeAsBytes(<int>[0, 1, 2, 3], flush: true);
  }

  @override
  Future<void> verify({
    required String taskId,
    required String filePath,
  }) async {
    _verificationCount++;
    if (_verificationCount == 1) {
      await _firstVerification.future;
    }
  }

  void completeFirstVerification() {
    if (!_firstVerification.isCompleted) {
      _firstVerification.complete();
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    cancelledTaskIds.add(taskId);
    completeFirstVerification();
  }
}
