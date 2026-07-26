import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/bangumi.dart';
import '../../../domain/models/douban_movie.dart';

part 'anime_ui_state.freezed.dart';

@freezed
abstract class AnimeUiState with _$AnimeUiState {
  const factory AnimeUiState({
    @Default('每日放送') String category,
    required String weekday,
    @Default('all') String animeType,
    @Default('all') String animeRegion,
    @Default('all') String animeYear,
    @Default('all') String animePlatform,
    @Default('T') String animeSort,
    @Default('all') String movieType,
    @Default('all') String movieRegion,
    @Default('all') String movieYear,
    @Default('T') String movieSort,
    @Default(<DoubanMovie>[]) List<DoubanMovie> animeItems,
    @Default(<BangumiItem>[]) List<BangumiItem> calendarItems,
    @Default(0) int page,
    @Default(false) bool loading,
    @Default(false) bool loadingMore,
    @Default(true) bool hasMore,
    String? error,
  }) = _AnimeUiState;
}
