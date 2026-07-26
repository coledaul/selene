import 'dart:async';

import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/sse_search_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/models/search_progress.dart';
import '../../../domain/models/search_result.dart';
import '../../../domain/models/search_session_event.dart';
import '../../../domain/models/video_info.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'search_ui_state.dart';

final class SearchViewModel extends ViewModel {
  SearchViewModel({
    required LibraryRepository libraryRepository,
    required SSESearchRepository searchSession,
    required SettingsRepository settingsRepository,
  }) : _libraryRepository = libraryRepository,
       _searchSession = searchSession,
       _settingsRepository = settingsRepository;

  final LibraryRepository _libraryRepository;
  final SSESearchRepository _searchSession;
  final SettingsRepository _settingsRepository;
  SearchUiState _state = const SearchUiState();
  StreamSubscription<SearchSessionEvent>? _eventSubscription;
  Timer? _resultsDebounce;
  final List<SearchResult> _pendingResults = <SearchResult>[];
  int _searchGeneration = 0;

  SearchUiState get state => _state;

  bool isFavorited(String source, String id) =>
      _libraryRepository.isFavorited(source, id);

  void updateQuery(String value) => _setState(_state.copyWith(query: value));

  Future<void> initialize() async {
    _subscribe();
    await _loadHistory();
  }

  Future<Result<void>> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const FailureResult(
        AppFailure(kind: FailureKind.validation, message: '请输入搜索内容'),
      );
    }
    final generation = ++_searchGeneration;
    _subscribe();
    try {
      await _searchSession.stopSearch();
      if (!_isCurrentSearch(generation)) {
        return const Success<void>(null);
      }
      _resultsDebounce?.cancel();
      _pendingResults.clear();
      _setState(
        _state.copyWith(
          query: normalized,
          results: const <SearchResult>[],
          status: SearchStatus.searching,
          aggregatedView: true,
          selectedSource: 'all',
          selectedYear: 'all',
          selectedTitle: 'all',
          sortOrder: SearchSortOrder.none,
          progress: null,
          error: null,
          warning: null,
        ),
      );
      await addHistory(normalized);
      if (!_isCurrentSearch(generation)) {
        return const Success<void>(null);
      }
      final settings = await _settingsRepository.load();
      if (!_isCurrentSearch(generation)) {
        return const Success<void>(null);
      }
      if (settings.isFailure) {
        _setState(
          _state.copyWith(
            status: SearchStatus.failure,
            error: settings.failureOrNull!.message,
          ),
        );
        return FailureResult(settings.failureOrNull!);
      }
      await _searchSession.startSearch(
        normalized,
        localSearchEnabled: settings.valueOrNull!.localSearch,
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      if (!_isCurrentSearch(generation)) {
        return const Success<void>(null);
      }
      final failure = AppFailure(
        kind: FailureKind.network,
        message: '搜索连接失败',
        cause: error,
        stackTrace: stackTrace,
      );
      _setState(
        _state.copyWith(status: SearchStatus.failure, error: failure.message),
      );
      return FailureResult(failure);
    }
  }

  Future<void> clearSearch() async {
    _searchGeneration++;
    await _searchSession.stopSearch();
    _pendingResults.clear();
    _resultsDebounce?.cancel();
    _setState(SearchUiState(history: _state.history));
  }

  Future<void> addHistory(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    final history = <String>[
      normalized,
      ..._state.history.where((item) => item != normalized),
    ];
    _setState(_state.copyWith(history: history));
    final result = await _libraryRepository.addSearchHistory(normalized);
    if (result.isFailure) {
      await _loadHistory(forceRefresh: true);
    }
  }

  Future<Result<void>> clearHistory() async {
    final result = await _libraryRepository.clearSearchHistory();
    if (result.isSuccess) {
      _setState(_state.copyWith(history: const <String>[]));
      return const Success<void>(null);
    }
    await _loadHistory(forceRefresh: true);
    return FailureResult(
      AppFailure(
        kind: FailureKind.network,
        message: result.failureOrNull?.message ?? '清空搜索历史失败',
      ),
    );
  }

  Future<Result<void>> deleteHistory(String value) async {
    final result = await _libraryRepository.deleteSearchHistory(value);
    if (result.isSuccess) {
      _setState(
        _state.copyWith(
          history: _state.history.where((item) => item != value).toList(),
        ),
      );
      return const Success<void>(null);
    }
    await _loadHistory(forceRefresh: true);
    return FailureResult(
      AppFailure(
        kind: FailureKind.network,
        message: result.failureOrNull?.message ?? '删除搜索历史失败',
      ),
    );
  }

  Future<void> refreshFavorites() async {
    await _libraryRepository.getFavorites(forceRefresh: true);
  }

  Future<Result<void>> addFavorite(VideoInfo video) async {
    final result = await _libraryRepository
        .addFavorite(video.source, video.id, <String, dynamic>{
          'cover': video.cover,
          'save_time': DateTime.now().millisecondsSinceEpoch,
          'source_name': video.sourceName,
          'title': video.title,
          'total_episodes': video.totalEpisodes,
          'year': video.year,
        });
    return result;
  }

  Future<Result<void>> removeFavorite(VideoInfo video) async {
    final result = await _libraryRepository.removeFavorite(
      video.source,
      video.id,
    );
    return result;
  }

  void setAggregatedView(bool value) =>
      _setState(_state.copyWith(aggregatedView: value));

  void setSource(String value) =>
      _setState(_state.copyWith(selectedSource: value));

  void setYear(String value) => _setState(_state.copyWith(selectedYear: value));

  void setTitle(String value) =>
      _setState(_state.copyWith(selectedTitle: value));

  void cycleSortOrder() {
    final next = switch (_state.sortOrder) {
      SearchSortOrder.none => SearchSortOrder.descending,
      SearchSortOrder.descending => SearchSortOrder.ascending,
      SearchSortOrder.ascending => SearchSortOrder.none,
    };
    _setState(_state.copyWith(sortOrder: next));
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    final result = await _libraryRepository.getSearchHistory(
      forceRefresh: forceRefresh,
    );
    _setState(_state.copyWith(history: result.valueOrNull ?? const <String>[]));
  }

  void _subscribe() {
    _eventSubscription ??= _searchSession.events.listen(_onSessionEvent);
  }

  void _onSessionEvent(SearchSessionEvent event) {
    switch (event) {
      case SearchSessionResults(:final results):
        _onResults(results);
      case SearchSessionProgress(:final progress):
        _onProgress(progress);
    }
  }

  void _onResults(List<SearchResult> results) {
    if (results.isEmpty || _state.status != SearchStatus.searching) return;
    _pendingResults.addAll(results);
    _resultsDebounce?.cancel();
    _resultsDebounce = Timer(
      const Duration(milliseconds: 50),
      _commitPendingResults,
    );
  }

  void _onProgress(SearchProgress progress) {
    if (!progress.isComplete) {
      if (_state.status != SearchStatus.searching) return;
      _setState(
        _state.copyWith(
          status: SearchStatus.searching,
          progress: progress,
          warning: progress.error ?? _state.warning,
        ),
      );
      return;
    }

    final results = _takePendingResults();
    _setState(
      _state.copyWith(
        results: results,
        status: progress.isFailure
            ? SearchStatus.failure
            : SearchStatus.success,
        progress: progress,
        error: progress.isFailure ? progress.error ?? '搜索失败，请重试' : null,
        warning: progress.isFailure ? null : progress.error,
      ),
    );
  }

  void _commitPendingResults() {
    final results = _takePendingResults();
    if (!identical(results, _state.results)) {
      _setState(_state.copyWith(results: results));
    }
  }

  List<SearchResult> _takePendingResults() {
    _resultsDebounce?.cancel();
    _resultsDebounce = null;
    if (_pendingResults.isEmpty) {
      return _state.results;
    }
    final merged = <SearchResult>[..._state.results, ..._pendingResults];
    _pendingResults.clear();
    return merged;
  }

  void _setState(SearchUiState value) =>
      updateState(_state, value, (next) => _state = next);

  bool _isCurrentSearch(int generation) =>
      isActive && generation == _searchGeneration;

  @override
  void dispose() {
    _searchGeneration++;
    _resultsDebounce?.cancel();
    unawaited(_eventSubscription?.cancel());
    _searchSession.dispose();
    super.dispose();
  }
}
