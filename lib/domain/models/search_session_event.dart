import 'search_progress.dart';
import 'search_result.dart';

sealed class SearchSessionEvent {
  const SearchSessionEvent();
}

final class SearchSessionResults extends SearchSessionEvent {
  SearchSessionResults(List<SearchResult> results)
    : results = List<SearchResult>.unmodifiable(results);

  final List<SearchResult> results;
}

final class SearchSessionProgress extends SearchSessionEvent {
  const SearchSessionProgress(this.progress);

  final SearchProgress progress;
}
