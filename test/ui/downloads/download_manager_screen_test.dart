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
import 'package:selene/ui/core/themes/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('初始化重试保持配色且显示等待状态 dark=$dark', (tester) async {
      final repository = _FakeDownloadRepository()
        ..initializationProblem = '初始化失败';
      await _pumpScreen(tester, repository, dark: dark);
      await tester.pumpAndSettle();
      final gate = Completer<void>();
      repository.initializeCompletion = gate;
      final beforeCalls = repository.initializeCount;
      await tester.tap(find.text('重试'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final button = find.byType(FilledButton);
      expect(find.text('正在重试…'), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      final surface = tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first,
      );
      expect(
        surface.color,
        Theme.of(tester.element(button)).colorScheme.primary,
      );
      await tester.tap(button);
      expect(repository.initializeCount, beforeCalls + 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsOneWidget);
    });
  }
  testWidgets('完成任务仅保留播放主操作，导出和删除通过更多菜单访问', (tester) async {
    await _pumpScreen(tester, _FakeDownloadRepository());
    expect(find.byTooltip('播放'), findsOneWidget);
    expect(find.byTooltip('导出'), findsNothing);
    expect(find.byTooltip('删除'), findsNothing);
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    expect(find.text('导出'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });

  for (final action in ['重试', '取消']) {
    testWidgets('$action 失败后给出明确反馈', (tester) async {
      final repository = _FakeDownloadRepository()
        ..actionError = StateError('模拟操作失败');
      repository.tasks[0] = repository.tasks[0].copyWith(
        durationMs: 60000,
        status: action == '重试'
            ? VideoDownloadStatus.failed
            : VideoDownloadStatus.downloading,
      );
      await _pumpScreen(tester, repository);
      await tester.tap(find.byTooltip(action));
      await tester.pumpAndSettle();
      expect(find.text('$action下载失败'), findsOneWidget);
    });
  }

  testWidgets('下载管理使用公共页面标题和设置入口', (tester) async {
    final repository = _FakeDownloadRepository();

    await _pumpScreen(tester, repository);

    expect(find.byType(AppPageBar), findsOneWidget);
    expect(find.text('下载管理'), findsOneWidget);
    expect(
      tester.widget<AppPageBar>(find.byType(AppPageBar)).titleIcon,
      isNull,
    );
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
    expect(find.byTooltip('更多操作'), findsOneWidget);

    await _selectMoreAction(tester, '导出');
    await tester.pumpAndSettle();

    expect(repository.exportedTaskIds, <String>['task-1']);
    expect(find.text('已导出'), findsOneWidget);
  });

  testWidgets('用户取消导出时不显示成功或失败提示', (tester) async {
    final repository = _FakeDownloadRepository()
      ..exportOutcome = DownloadExportOutcome.cancelled;

    await _pumpScreen(tester, repository);
    await _selectMoreAction(tester, '导出');
    await tester.pumpAndSettle();

    expect(repository.exportedTaskIds, <String>['task-1']);
    expect(find.text('已导出'), findsNothing);
    expect(find.text('导出下载失败，请重试'), findsNothing);
  });

  testWidgets('导出异常时显示明确失败提示', (tester) async {
    final repository = _FakeDownloadRepository()
      ..exportError = StateError('模拟导出失败');

    await _pumpScreen(tester, repository);
    await _selectMoreAction(tester, '导出');
    await tester.pumpAndSettle();

    expect(find.text('导出下载失败，请重试'), findsOneWidget);
  });

  testWidgets('导出期间目标任务显示进度且按钮不可重复触发', (tester) async {
    final completion = Completer<void>();
    final repository = _FakeDownloadRepository()..exportCompletion = completion;

    await _pumpScreen(tester, repository);
    await _selectMoreAction(tester, '导出');
    await tester.pump();

    final exportButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(IconButton),
      ),
    );
    expect(exportButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final playButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('播放'),
        matching: find.byType(IconButton),
      ),
    );
    expect(playButton.onPressed, isNotNull);

    completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('已导出'), findsOneWidget);
  });

  testWidgets('删除需要确认，取消不删除，失败明确提示', (tester) async {
    final repository = _FakeDownloadRepository()
      ..actionError = StateError('删除失败');
    await _pumpScreen(tester, repository);
    await _selectMoreAction(tester, '删除');
    await tester.pumpAndSettle();
    expect(repository.deletedTaskIds, isEmpty);
    final deleteFinder = find.widgetWithText(FilledButton, '删除');
    final deleteMaterial = tester.widget<Material>(
      find.descendant(of: deleteFinder, matching: find.byType(Material)).first,
    );
    expect(
      deleteMaterial.color,
      Theme.of(tester.element(deleteFinder)).colorScheme.error,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repository.deletedTaskIds, isEmpty);
    await _selectMoreAction(tester, '删除');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    expect(repository.deletedTaskIds, ['task-1']);
    expect(find.text('删除下载失败'), findsOneWidget);
  });

  for (final action in ['重试', '取消']) {
    testWidgets('$action 等待时保持加载反馈并防止重复触发', (tester) async {
      final completion = Completer<void>();
      final repository = _FakeDownloadRepository()
        ..actionCompletion = completion;
      repository.tasks[0] = repository.tasks[0].copyWith(
        status: action == '重试'
            ? VideoDownloadStatus.failed
            : VideoDownloadStatus.queued,
      );
      await _pumpScreen(tester, repository);
      await tester.tap(find.byTooltip(action));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(action),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(repository.actionCount, 1);
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('播放入口仍能进入本地播放器', (tester) async {
    final repository = _FakeDownloadRepository();
    repository.tasks[0] = _completedTask(filePath: null);
    await _pumpScreen(tester, repository);
    await tester.tap(find.byTooltip('播放'));
    await tester.pumpAndSettle();
    expect(find.byType(DownloadedVideoPlayerScreen), findsOneWidget);
    expect(find.text('本地文件不存在'), findsOneWidget);
  });

  for (final layout in [
    (size: const Size(320, 568), scale: 1.0, dark: false),
    (size: const Size(375, 667), scale: 2.0, dark: true),
    (size: const Size(667, 375), scale: 2.0, dark: false),
  ]) {
    testWidgets('任务卡片适配 ${layout.size} 字号 ${layout.scale}', (tester) async {
      tester.view.physicalSize = layout.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeDownloadRepository();
      await _pumpScreen(
        tester,
        repository,
        dark: layout.dark,
        textScale: layout.scale,
      );
      for (final status in VideoDownloadStatus.values) {
        repository.tasks[0] = repository.tasks[0].copyWith(
          title: '这是一个比较长的视频标题，需要在小屏幕上正常显示',
          status: status,
          durationMs: 60000,
          downloadedBytes: 123456789,
          bytesPerSecond: 1024000,
          errorMessage: '下载失败，请检查网络后重试',
        );
        repository.notifyListeners();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: status.name);
        final card = tester.getRect(find.byType(Card));
        for (final icon in tester.widgetList<IconButton>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(IconButton),
          ),
        )) {
          final rect = tester.getRect(find.byWidget(icon));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.right, lessThanOrEqualTo(card.right));
        }
      }
    });
  }
}

Future<void> _selectMoreAction(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('更多操作'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeDownloadRepository repository, {
  bool dark = false,
  double textScale = 1,
}) async {
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
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
  Object? actionError;
  Completer<void>? actionCompletion;
  int actionCount = 0;
  String? initializationProblem;
  Completer<void>? initializeCompletion;
  int initializeCount = 0;
  final List<String> deletedTaskIds = [];
  final List<String> exportedTaskIds = <String>[];

  @override
  bool get isInitialized => initializationProblem == null;

  @override
  String? get initializationError => initializationProblem;

  @override
  int get maxConcurrentDownloads => 3;

  @override
  int get activeCount => 0;

  @override
  int get queuedCount => 0;

  @override
  int get completedCount => 1;

  @override
  Future<void> initialize() async {
    initializeCount++;
    await initializeCompletion?.future;
  }

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
  Future<void> cancel(String taskId) async {
    actionCount++;
    await actionCompletion?.future;
    if (actionError case final error?) throw error;
  }

  @override
  Future<void> retry(String taskId) async {
    actionCount++;
    await actionCompletion?.future;
    if (actionError case final error?) throw error;
  }

  @override
  Future<void> delete(String taskId) async {
    deletedTaskIds.add(taskId);
    if (actionError case final error?) throw error;
  }

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
