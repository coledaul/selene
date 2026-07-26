import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/app_version.dart';
import '../../../domain/models/favorite_item.dart';
import '../../../domain/models/play_record.dart';
import '../../../domain/models/video_info.dart';

part 'home_ui_state.freezed.dart';

@freezed
abstract class HomeUiState with _$HomeUiState {
  const factory HomeUiState({
    @Default(0) int bottomNavigationIndex,
    @Default(0) int topTabIndex,
    @Default(<PlayRecord>[]) List<PlayRecord> playRecords,
    @Default(<FavoriteItem>[]) List<FavoriteItem> favorites,
    @Default(false) bool playRecordsLoading,
    String? playRecordsError,
    @Default(false) bool favoritesLoading,
    String? favoritesError,
    @Default(<VideoInfo>[]) List<VideoInfo> hotMovies,
    @Default(<VideoInfo>[]) List<VideoInfo> hotTvShows,
    @Default(<VideoInfo>[]) List<VideoInfo> hotShows,
    @Default(<VideoInfo>[]) List<VideoInfo> todayAnime,
    @Default(<String>{}) Set<String> failedSections,
    @Default(<String>{}) Set<String> loadingSections,
    AppVersionInfo? availableUpdate,
  }) = _HomeUiState;
}
