import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/bangumi.dart';
import '../../../domain/models/douban_movie.dart';

part 'video_metadata_ui_state.freezed.dart';

@freezed
abstract class VideoMetadataUiState with _$VideoMetadataUiState {
  const factory VideoMetadataUiState({
    DoubanMovieDetails? doubanDetails,
    BangumiDetails? bangumiDetails,
    @Default(false) bool loadingDouban,
    @Default(false) bool loadingBangumi,
    String? doubanError,
    String? bangumiError,
  }) = _VideoMetadataUiState;
}
