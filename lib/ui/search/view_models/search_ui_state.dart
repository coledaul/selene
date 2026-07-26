import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/search_progress.dart';
import '../../../domain/models/search_result.dart';

part 'search_ui_state.freezed.dart';

enum SearchSortOrder { none, ascending, descending }

enum SearchStatus { idle, searching, success, failure }

@freezed
abstract class SearchUiState with _$SearchUiState {
  const SearchUiState._();

  const factory SearchUiState({
    @Default('') String query,
    @Default(<String>[]) List<String> history,
    @Default(<SearchResult>[]) List<SearchResult> results,
    @Default(SearchStatus.idle) SearchStatus status,
    @Default(true) bool aggregatedView,
    @Default('all') String selectedSource,
    @Default('all') String selectedYear,
    @Default('all') String selectedTitle,
    @Default(SearchSortOrder.none) SearchSortOrder sortOrder,
    SearchProgress? progress,
    String? error,
    String? warning,
  }) = _SearchUiState;

  bool get searched => status != SearchStatus.idle;

  bool get receivedStart => progress != null;

  List<SearchResult> get filteredResults {
    final filtered = results
        .where((result) {
          return (selectedSource == 'all' ||
                  result.sourceName == selectedSource) &&
              (selectedYear == 'all' || result.year == selectedYear) &&
              (selectedTitle == 'all' || result.title == selectedTitle);
        })
        .toList(growable: false);
    if (sortOrder == SearchSortOrder.none) {
      return filtered;
    }
    return filtered.toList()..sort((left, right) {
      final leftYear = int.tryParse(left.year);
      final rightYear = int.tryParse(right.year);
      if (leftYear == null && rightYear == null) return 0;
      if (leftYear == null) return 1;
      if (rightYear == null) return -1;
      return sortOrder == SearchSortOrder.descending
          ? rightYear.compareTo(leftYear)
          : leftYear.compareTo(rightYear);
    });
  }

  bool get finished => switch (status) {
    SearchStatus.success || SearchStatus.failure => true,
    SearchStatus.idle || SearchStatus.searching => false,
  };
}
