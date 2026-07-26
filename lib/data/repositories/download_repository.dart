import 'package:flutter/foundation.dart';

import '../../domain/models/video_download_task.dart';
import '../../domain/models/search_result.dart';

abstract interface class DownloadRepository implements Listenable {
  List<VideoDownloadTask> get tasks;
  bool get isInitialized;
  String? get initializationError;
  int get maxConcurrentDownloads;
  int get activeCount;
  int get queuedCount;
  int get completedCount;

  Future<void> initialize();
  Future<void> setMaxConcurrentDownloads(int value);
  Future<List<VideoDownloadTask>> enqueueAll(
    Iterable<VideoDownloadRequest> requests,
  );
  Future<List<VideoDownloadTask>> enqueueEpisodes({
    required SearchResult detail,
    required Iterable<int> episodeIndexes,
  });
  Future<void> cancel(String taskId);
  Future<void> retry(String taskId);
  Future<void> delete(String taskId);
  Future<String?> completedPathFor({
    required String source,
    required String contentId,
    required int episodeIndex,
  });
  void dispose();
}
