import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/douban_movie.dart';
import '../../../domain/models/player_models.dart';
import '../../../domain/models/search_result.dart';

part 'player_ui_state.freezed.dart';

@freezed
abstract class PlayerUiState with _$PlayerUiState {
  const factory PlayerUiState({
    SearchResult? currentDetail,
    @Default('') String searchTitle,
    @Default('') String videoTitle,
    @Default('') String videoDescription,
    @Default('') String videoYear,
    @Default('') String videoCover,
    @Default(0) int doubanId,
    DoubanMovieDetails? doubanDetails,
    @Default('') String currentSource,
    @Default('') String currentId,
    @Default(false) bool preferSource,
    @Default(0) int totalEpisodes,
    @Default(0) int currentEpisodeIndex,
    @Default(false) bool favorite,
    @Default(false) bool loading,
    @Default(0) double loadingProgress,
    @Default('') String loadingMessage,
    @Default('') String loadingEmoji,
    String? errorMessage,
    String? warningMessage,
    @Default(0) int resumeEpisodeIndex,
    @Default(0) int resumePlayTime,
    @Default(<SearchResult>[]) List<SearchResult> sources,
    @Default(<String, PlayerSourceSpeed>{})
    Map<String, PlayerSourceSpeed> sourceSpeeds,
  }) = _PlayerUiState;
}
