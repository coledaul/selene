import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/download_repository.dart';
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
  Future<String?> completedPathFor({
    required String source,
    required String contentId,
    required int episodeIndex,
  }) async => null;
}
