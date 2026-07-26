import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/video_download_task.dart';

part 'download_ui_state.freezed.dart';

@freezed
abstract class DownloadUiState with _$DownloadUiState {
  const factory DownloadUiState({
    @Default(<VideoDownloadTask>[]) List<VideoDownloadTask> tasks,
    @Default(false) bool initialized,
    String? initializationError,
    @Default(3) int maxConcurrentDownloads,
  }) = _DownloadUiState;
}
