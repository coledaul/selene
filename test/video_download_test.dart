import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/features/video_download/application/video_download_manager.dart';
import 'package:selene/features/video_download/domain/video_download_task.dart';
import 'package:selene/features/video_download/infrastructure/download_file_store.dart';
import 'package:selene/features/video_download/infrastructure/download_task_store.dart';
import 'package:selene/features/video_download/infrastructure/ffmpeg_download_engine.dart';

void main() {
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
        engine.probe(mediaUrl: 'file:///private/video.mkv', headers: const {}),
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

  group('VideoDownloadManager', () {
    late Directory temporaryDirectory;
    late _MemoryTaskStore taskStore;
    late _FakeDownloadEngine engine;
    late VideoDownloadManager manager;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'selene-download-test-',
      );
      taskStore = _MemoryTaskStore();
      engine = _FakeDownloadEngine();
      manager = VideoDownloadManager(
        taskStore: taskStore,
        fileStore: DownloadFileStore(
          rootDirectoryProvider: () async => temporaryDirectory,
        ),
        engine: engine,
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
      await manager.enqueueAll(<VideoDownloadRequest>[
        _request(),
        _request(),
      ]);

      await _waitUntil(() => manager.completedCount == 1);

      expect(manager.tasks, hasLength(1));
      expect(engine.downloadCount, 1);
      expect(manager.tasks.single.filePath, endsWith('.mkv'));
      expect(await File(manager.tasks.single.filePath!).exists(), isTrue);
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
      final interruptedTask =
          VideoDownloadTask.fromRequest(_request()).copyWith(
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
      manager = VideoDownloadManager(
        taskStore: taskStore,
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
      manager = VideoDownloadManager(
        taskStore: failOnceStore,
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
  Future<void> verify(String filePath) async {
    if (!await File(filePath).exists()) {
      throw const DownloadEngineException('测试文件不存在');
    }
  }

  @override
  Future<void> cancel(String taskId) async {}
}
