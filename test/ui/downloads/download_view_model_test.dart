import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/download_repository.dart';
import 'package:selene/domain/models/download_export_outcome.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/downloads/view_models/download_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('Repository 通知会同步为不可变下载状态', () {
    final repository = _FakeDownloadRepository();
    final viewModel = DownloadViewModel(repository: repository);

    repository
      ..initialized = true
      ..maxConcurrentDownloads = 4
      ..notifyListeners();

    expect(viewModel.state.initialized, isTrue);
    expect(viewModel.state.maxConcurrentDownloads, 4);
    viewModel.dispose();
  });

  test('并发设置通过 Command 调用 Repository', () async {
    final repository = _FakeDownloadRepository();
    final viewModel = DownloadViewModel(repository: repository);

    final result = await viewModel.setConcurrency.execute(5);

    expect(result, isA<Success<void>>());
    expect(repository.maxConcurrentDownloads, 5);
    viewModel.dispose();
  });

  test('导出 Command 保留 Repository 的成功和取消结果', () async {
    final repository = _FakeDownloadRepository();
    final viewModel = DownloadViewModel(repository: repository);

    var result = await viewModel.export.execute('task-1');

    expect(result, isA<Success<DownloadExportOutcome>>());
    expect(result?.valueOrNull, DownloadExportOutcome.exported);
    expect(repository.exportedTaskIds, <String>['task-1']);

    repository.exportOutcome = DownloadExportOutcome.cancelled;
    result = await viewModel.export.execute('task-2');

    expect(result, isA<Success<DownloadExportOutcome>>());
    expect(result?.valueOrNull, DownloadExportOutcome.cancelled);
    viewModel.dispose();
  });

  test('导出失败映射为存储错误', () async {
    final repository = _FakeDownloadRepository()
      ..exportError = StateError('模拟导出失败');
    final viewModel = DownloadViewModel(repository: repository);

    final result = await viewModel.export.execute('task-1');

    expect(result, isA<FailureResult<DownloadExportOutcome>>());
    expect(result?.failureOrNull?.kind, FailureKind.storage);
    expect(result?.failureOrNull?.message, '导出下载失败，请重试');
    viewModel.dispose();
  });

  test('导出期间记录目标任务并拒绝第二个导出', () async {
    final repository = _FakeDownloadRepository();
    final completion = Completer<void>();
    repository.exportCompletion = completion;
    final viewModel = DownloadViewModel(repository: repository);

    final firstExport = viewModel.export.execute('task-1');
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.export.running, isTrue);
    expect(viewModel.exportingTaskId, 'task-1');
    expect(await viewModel.export.execute('task-2'), isNull);

    completion.complete();
    await firstExport;
    expect(viewModel.export.running, isFalse);
    expect(viewModel.exportingTaskId, isNull);
    viewModel.dispose();
  });
}

final class _FakeDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  @override
  List<VideoDownloadTask> tasks = <VideoDownloadTask>[];

  bool initialized = false;

  @override
  bool get isInitialized => initialized;

  @override
  String? initializationError;

  @override
  int maxConcurrentDownloads = 3;

  @override
  int get activeCount => 0;

  @override
  int get queuedCount => 0;

  @override
  int get completedCount => 0;

  DownloadExportOutcome exportOutcome = DownloadExportOutcome.exported;
  Object? exportError;
  Completer<void>? exportCompletion;
  final List<String> exportedTaskIds = <String>[];

  @override
  Future<void> initialize() async {
    initialized = true;
    notifyListeners();
  }

  @override
  Future<void> setMaxConcurrentDownloads(int value) async {
    maxConcurrentDownloads = value;
    notifyListeners();
  }

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
