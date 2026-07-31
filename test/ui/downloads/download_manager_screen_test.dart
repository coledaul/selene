import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/download_repository.dart';
import 'package:selene/domain/models/download_export_outcome.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/downloads/view_models/download_view_model.dart';
import 'package:selene/ui/downloads/widgets/downloaded_video_player_screen.dart';
import 'package:selene/ui/downloads/widgets/download_manager_screen.dart';
import 'package:selene/ui/core/widgets/app_page_bar.dart';

void main() {
  testWidgets('下载管理使用公共页面标题和设置入口', (tester) async {
    final repository = _FakeDownloadRepository();

    await _pumpScreen(tester, repository);

    expect(find.byType(AppPageBar), findsOneWidget);
    expect(find.text('下载管理'), findsOneWidget);
    expect(find.byTooltip('下载设置'), findsOneWidget);
  });

  testWidgets('本地文件缺失页面保留统一标题和明确错误', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadedVideoPlayerScreen(task: _completedTask(filePath: null)),
      ),
    );

    expect(find.byType(AppPageBar), findsOneWidget);
    expect(find.text('测试视频 · 第 1 集'), findsOneWidget);
    expect(find.text('本地文件不存在'), findsOneWidget);
  });

  testWidgets('本地文件正常时由播放器独占标题和返回入口', (tester) async {
    String? capturedTitle;
    VoidCallback? capturedBack;
    await tester.pumpWidget(
      MaterialApp(
        home: DownloadedVideoPlayerScreen(
          task: _completedTask(),
          playerBuilder:
              ({
                required task,
                required filePath,
                required overlayTitle,
                required onBackPressed,
              }) {
                capturedTitle = overlayTitle;
                capturedBack = onBackPressed;
                return const ColoredBox(
                  key: Key('fake-player'),
                  color: Colors.black,
                );
              },
        ),
      ),
    );

    expect(find.byType(AppPageBar), findsNothing);
    expect(find.byKey(const Key('fake-player')), findsOneWidget);
    expect(capturedTitle, '测试视频 · 第 1 集');
    expect(capturedBack, isNotNull);
  });

  testWidgets('完成任务显示导出入口并在成功后提示', (tester) async {
    final repository = _FakeDownloadRepository();

    await _pumpScreen(tester, repository);
    expect(find.byTooltip('导出'), findsOneWidget);

    await tester.tap(find.byTooltip('导出'));
    await tester.pumpAndSettle();

    expect(repository.exportedTaskIds, <String>['task-1']);
    expect(find.text('已导出'), findsOneWidget);
  });

  testWidgets('用户取消导出时不显示成功或失败提示', (tester) async {
    final repository = _FakeDownloadRepository()
      ..exportOutcome = DownloadExportOutcome.cancelled;

    await _pumpScreen(tester, repository);
    await tester.tap(find.byTooltip('导出'));
    await tester.pumpAndSettle();

    expect(repository.exportedTaskIds, <String>['task-1']);
    expect(find.text('已导出'), findsNothing);
    expect(find.text('导出下载失败，请重试'), findsNothing);
  });

  testWidgets('导出异常时显示明确失败提示', (tester) async {
    final repository = _FakeDownloadRepository()
      ..exportError = StateError('模拟导出失败');

    await _pumpScreen(tester, repository);
    await tester.tap(find.byTooltip('导出'));
    await tester.pumpAndSettle();

    expect(find.text('导出下载失败，请重试'), findsOneWidget);
  });

  testWidgets('导出期间目标任务显示进度且按钮不可重复触发', (tester) async {
    final completion = Completer<void>();
    final repository = _FakeDownloadRepository()..exportCompletion = completion;

    await _pumpScreen(tester, repository);
    await tester.tap(find.byTooltip('导出'));
    await tester.pump();

    final exportButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(IconButton),
      ),
    );
    expect(exportButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('已导出'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeDownloadRepository repository,
) async {
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: DownloadManagerScreen(
        viewModelFactory: () => DownloadViewModel(repository: repository),
      ),
    ),
  );
}

final class _FakeDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  _FakeDownloadRepository() : tasks = <VideoDownloadTask>[_completedTask()];

  @override
  final List<VideoDownloadTask> tasks;

  DownloadExportOutcome exportOutcome = DownloadExportOutcome.exported;
  Object? exportError;
  Completer<void>? exportCompletion;
  final List<String> exportedTaskIds = <String>[];

  @override
  bool get isInitialized => true;

  @override
  String? get initializationError => null;

  @override
  int get maxConcurrentDownloads => 3;

  @override
  int get activeCount => 0;

  @override
  int get queuedCount => 0;

  @override
  int get completedCount => 1;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setMaxConcurrentDownloads(int value) async {}

  @override
  Future<List<VideoDownloadTask>> enqueueAll(
    Iterable<VideoDownloadRequest> requests,
  ) async => <VideoDownloadTask>[];

  @override
  Future<List<VideoDownloadTask>> enqueueEpisodes({
    required SearchResult detail,
    required Iterable<int> episodeIndexes,
  }) async => <VideoDownloadTask>[];

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> retry(String taskId) async {}

  @override
  Future<void> delete(String taskId) async {}

  @override
  Future<DownloadExportOutcome> export(String taskId) async {
    exportedTaskIds.add(taskId);
    final error = exportError;
    if (error != null) {
      throw error;
    }
    await exportCompletion?.future;
    return exportOutcome;
  }

  @override
  Future<String?> completedPathFor({
    required String source,
    required String contentId,
    required int episodeIndex,
  }) async => null;
}

VideoDownloadTask _completedTask({
  String? filePath = '/private/测试视频-第 1 集.mkv',
}) {
  final now = DateTime(2026, 7, 28);
  return VideoDownloadTask(
    id: 'task-1',
    key: VideoDownloadRequest.buildKey(
      source: 'source-a',
      contentId: 'video-1',
      episodeIndex: 0,
    ),
    source: 'source-a',
    contentId: 'video-1',
    sourceName: '测试源',
    title: '测试视频',
    coverUrl: '',
    episodeIndex: 0,
    episodeTitle: '第 1 集',
    totalEpisodes: 1,
    mediaUrl: 'https://example.com/video.m3u8',
    headers: const <String, String>{},
    status: VideoDownloadStatus.completed,
    progress: 1,
    downloadedBytes: 4,
    filePath: filePath,
    createdAt: now,
    updatedAt: now,
    completedAt: now,
  );
}
