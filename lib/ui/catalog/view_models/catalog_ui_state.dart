import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/douban_movie.dart';

part 'catalog_ui_state.freezed.dart';

@freezed
abstract class CatalogUiState with _$CatalogUiState {
  const factory CatalogUiState({
    @Default(<DoubanMovie>[]) List<DoubanMovie> items,
    required String category,
    required String secondary,
    @Default('all') String type,
    @Default('all') String region,
    @Default('all') String year,
    @Default('all') String platform,
    @Default('T') String sort,
    @Default(0) int page,
    @Default(false) bool loading,
    @Default(false) bool loadingMore,
    @Default(true) bool hasMore,
    String? error,
  }) = _CatalogUiState;
}
