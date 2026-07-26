import '../../../data/repositories/catalog_repository.dart';
import '../../../domain/models/catalog.dart';
import '../../../domain/models/douban_movie.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'catalog_ui_state.dart';

final class CatalogViewModel extends ViewModel {
  CatalogViewModel({
    required CatalogRepository repository,
    required this.definition,
    this.pageLimit = 25,
  }) : _repository = repository,
       _state = CatalogUiState(
         category: definition.initialCategory,
         secondary: definition.initialSecondary,
       );

  final CatalogRepository _repository;
  final CatalogDefinition definition;
  final int pageLimit;
  CatalogUiState _state;
  int _requestGeneration = 0;

  CatalogUiState get state => _state;

  Future<Result<void>> initialize() => refresh();

  Future<Result<void>> refresh() async {
    final generation = ++_requestGeneration;
    _setState(
      _state.copyWith(
        items: const <DoubanMovie>[],
        page: 0,
        loading: true,
        loadingMore: false,
        hasMore: true,
        error: null,
      ),
    );
    return _fetch(generation: generation, append: false);
  }

  Future<Result<void>> loadMore() async {
    if (_state.loading || _state.loadingMore || !_state.hasMore) {
      return const Success<void>(null);
    }
    final generation = _requestGeneration;
    _setState(_state.copyWith(loadingMore: true));
    return _fetch(generation: generation, append: true);
  }

  Future<Result<void>> selectCategory(String value) {
    _setState(
      _state.copyWith(
        category: value,
        secondary: definition.initialSecondary,
        type: 'all',
        region: 'all',
        year: 'all',
        platform: 'all',
        sort: 'T',
      ),
    );
    return refresh();
  }

  Future<Result<void>> selectSecondary(String value) {
    _setState(_state.copyWith(secondary: value));
    return refresh();
  }

  Future<Result<void>> selectType(String value) =>
      _updateFilter(_state.copyWith(type: value));

  Future<Result<void>> selectRegion(String value) =>
      _updateFilter(_state.copyWith(region: value));

  Future<Result<void>> selectYear(String value) =>
      _updateFilter(_state.copyWith(year: value));

  Future<Result<void>> selectPlatform(String value) =>
      _updateFilter(_state.copyWith(platform: value));

  Future<Result<void>> selectSort(String value) =>
      _updateFilter(_state.copyWith(sort: value));

  Future<Result<void>> _updateFilter(CatalogUiState state) {
    _setState(state);
    return refresh();
  }

  Future<Result<void>> _fetch({
    required int generation,
    required bool append,
  }) async {
    final result = await _repository.fetch(
      CatalogQuery(
        definition: definition,
        category: _state.category,
        secondary: _state.secondary,
        type: _state.type,
        region: _state.region,
        year: _state.year,
        platform: _state.platform,
        sort: _state.sort,
        page: _state.page,
        pageLimit: pageLimit,
      ),
    );
    if (generation != _requestGeneration) {
      return const Success<void>(null);
    }
    if (result case FailureResult<List<DoubanMovie>>(:final failure)) {
      _setState(
        _state.copyWith(
          loading: false,
          loadingMore: false,
          error: append ? _state.error : failure.message,
        ),
      );
      return FailureResult(failure);
    }
    final page = result.valueOrNull ?? const <DoubanMovie>[];
    _setState(
      _state.copyWith(
        items: append
            ? List<DoubanMovie>.unmodifiable(<DoubanMovie>[
                ..._state.items,
                ...page,
              ])
            : page,
        page: _state.page + 1,
        loading: false,
        loadingMore: false,
        hasMore: page.isNotEmpty,
        error: null,
      ),
    );
    return const Success<void>(null);
  }

  void _setState(CatalogUiState value) =>
      updateState(_state, value, (next) => _state = next);
}
