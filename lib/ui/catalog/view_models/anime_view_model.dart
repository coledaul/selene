import '../../../data/repositories/anime_repository.dart';
import '../../../domain/models/anime_catalog.dart';
import '../../../domain/models/douban_movie.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'anime_ui_state.dart';

final class AnimeViewModel extends ViewModel {
  AnimeViewModel({required AnimeRepository repository, this.pageLimit = 25})
    : _repository = repository,
      _state = AnimeUiState(weekday: DateTime.now().weekday.toString());

  final AnimeRepository _repository;
  final int pageLimit;
  AnimeUiState _state;
  int _generation = 0;

  AnimeUiState get state => _state;

  Future<Result<void>> initialize() => refresh();

  Future<Result<void>> refresh() async {
    final generation = ++_generation;
    _setState(
      _state.copyWith(
        animeItems: const <DoubanMovie>[],
        calendarItems: const [],
        page: 0,
        loading: true,
        loadingMore: false,
        hasMore: true,
        error: null,
      ),
    );
    return _fetch(generation, append: false);
  }

  Future<Result<void>> loadMore() async {
    if (_state.category == '每日放送' ||
        _state.loading ||
        _state.loadingMore ||
        !_state.hasMore) {
      return const Success<void>(null);
    }
    _setState(_state.copyWith(loadingMore: true));
    return _fetch(_generation, append: true);
  }

  Future<Result<void>> selectCategory(String value) {
    _setState(
      AnimeUiState(category: value, weekday: DateTime.now().weekday.toString()),
    );
    return refresh();
  }

  Future<Result<void>> selectWeekday(String value) =>
      _update(_state.copyWith(weekday: value));
  Future<Result<void>> selectAnimeType(String value) =>
      _update(_state.copyWith(animeType: value));
  Future<Result<void>> selectAnimeRegion(String value) =>
      _update(_state.copyWith(animeRegion: value));
  Future<Result<void>> selectAnimeYear(String value) =>
      _update(_state.copyWith(animeYear: value));
  Future<Result<void>> selectAnimePlatform(String value) =>
      _update(_state.copyWith(animePlatform: value));
  Future<Result<void>> selectAnimeSort(String value) =>
      _update(_state.copyWith(animeSort: value));
  Future<Result<void>> selectMovieType(String value) =>
      _update(_state.copyWith(movieType: value));
  Future<Result<void>> selectMovieRegion(String value) =>
      _update(_state.copyWith(movieRegion: value));
  Future<Result<void>> selectMovieYear(String value) =>
      _update(_state.copyWith(movieYear: value));
  Future<Result<void>> selectMovieSort(String value) =>
      _update(_state.copyWith(movieSort: value));

  Future<Result<void>> _update(AnimeUiState state) {
    _setState(state);
    return refresh();
  }

  Future<Result<void>> _fetch(int generation, {required bool append}) async {
    if (_state.category == '每日放送') {
      final result = await _repository.getCalendar(int.parse(_state.weekday));
      if (generation != _generation) return const Success<void>(null);
      if (result.isFailure) return _setFailure(result.failureOrNull!);
      _setState(
        _state.copyWith(
          calendarItems: result.valueOrNull ?? const [],
          loading: false,
          hasMore: false,
        ),
      );
      return const Success<void>(null);
    }

    final series = _state.category == '番剧';
    final result = await _repository.getCatalog(
      AnimeCatalogQuery(
        type: series ? AnimeCatalogType.series : AnimeCatalogType.movie,
        genre: series ? _state.animeType : _state.movieType,
        region: series ? _state.animeRegion : _state.movieRegion,
        year: series ? _state.animeYear : _state.movieYear,
        platform: series ? _state.animePlatform : 'all',
        sort: series ? _state.animeSort : _state.movieSort,
        page: _state.page,
        pageLimit: pageLimit,
      ),
    );
    if (generation != _generation) return const Success<void>(null);
    if (result.isFailure) return _setFailure(result.failureOrNull!);
    final page = result.valueOrNull ?? const <DoubanMovie>[];
    _setState(
      _state.copyWith(
        animeItems: append
            ? <DoubanMovie>[..._state.animeItems, ...page]
            : page,
        page: _state.page + 1,
        loading: false,
        loadingMore: false,
        hasMore: page.isNotEmpty,
      ),
    );
    return const Success<void>(null);
  }

  FailureResult<void> _setFailure(AppFailure failure) {
    _setState(
      _state.copyWith(
        loading: false,
        loadingMore: false,
        error: failure.message,
      ),
    );
    return FailureResult<void>(failure);
  }

  void _setState(AnimeUiState value) =>
      updateState(_state, value, (next) => _state = next);
}
