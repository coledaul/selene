import 'dart:async';

import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/anime_repository.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/update_repository.dart';
import '../../../domain/models/app_version.dart';
import '../../../domain/models/bangumi.dart';
import '../../../domain/models/douban_movie.dart';
import '../../../domain/models/play_record.dart';
import '../../../domain/models/catalog.dart';
import '../../../utils/command.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'home_ui_state.dart';

enum HomeRecommendationKind { movie, tv, anime, show }

final class HomeViewModel extends ViewModel {
  HomeViewModel({
    required LibraryRepository libraryRepository,
    required CatalogRepository catalogRepository,
    required AnimeRepository animeRepository,
    required UpdateRepository updateRepository,
    Duration updateDelay = const Duration(seconds: 3),
  }) : _libraryRepository = libraryRepository,
       _catalogRepository = catalogRepository,
       _animeRepository = animeRepository,
       _updateRepository = updateRepository,
       _updateDelay = updateDelay {
    refreshLibrary = Command0<void>(_refreshLibrary)
      ..addListener(_notifyCommandChanged);
    refreshPlayRecords = Command0<void>(_refreshPlayRecordsOnly)
      ..addListener(_notifyCommandChanged);
    refreshFavorites = Command0<void>(_refreshFavoritesOnly)
      ..addListener(_notifyCommandChanged);
    refreshContent = Command0<void>(_refreshContent)
      ..addListener(_notifyCommandChanged);
    refreshRecommendation = Command1<void, HomeRecommendationKind>(
      _refreshRecommendation,
    )..addListener(_notifyCommandChanged);
    deleteRecord = Command1<void, PlayRecord>(_deleteRecord)
      ..addListener(_notifyCommandChanged);
    addFavorite = Command1<void, PlayRecord>(_addFavorite)
      ..addListener(_notifyCommandChanged);
    removeFavorite = Command1<void, PlayRecord>(_removeFavorite)
      ..addListener(_notifyCommandChanged);
    clearRecords = Command0<void>(_clearRecords)
      ..addListener(_notifyCommandChanged);
    dismissUpdate = Command1<void, String>(_dismissUpdate)
      ..addListener(_notifyCommandChanged);
  }

  final LibraryRepository _libraryRepository;
  final CatalogRepository _catalogRepository;
  final AnimeRepository _animeRepository;
  final UpdateRepository _updateRepository;
  final Duration _updateDelay;
  HomeUiState _state = const HomeUiState();
  Timer? _updateTimer;

  late final Command0<void> refreshLibrary;
  late final Command0<void> refreshPlayRecords;
  late final Command0<void> refreshFavorites;
  late final Command0<void> refreshContent;
  late final Command1<void, HomeRecommendationKind> refreshRecommendation;
  late final Command1<void, PlayRecord> deleteRecord;
  late final Command1<void, PlayRecord> addFavorite;
  late final Command1<void, PlayRecord> removeFavorite;
  late final Command0<void> clearRecords;
  late final Command1<void, String> dismissUpdate;

  HomeUiState get state => _state;

  bool isFavorited(String source, String id) =>
      _state.favorites.any((item) => item.source == source && item.id == id);

  void initialize() {
    unawaited(refreshLibrary.execute());
    unawaited(_warmSearchHistory());
    unawaited(refreshContent.execute());
    _updateTimer = Timer(_updateDelay, () => unawaited(_checkForUpdate()));
  }

  void selectBottomNavigation(int index) {
    if (index == _state.bottomNavigationIndex) {
      return;
    }
    _setState(_state.copyWith(bottomNavigationIndex: index));
  }

  void selectTopTab(int index) {
    if (index == _state.topTabIndex) {
      return;
    }
    _setState(_state.copyWith(topTabIndex: index));
  }

  void selectHome() {
    _setState(_state.copyWith(bottomNavigationIndex: 0, topTabIndex: 0));
  }

  void consumeAvailableUpdate() {
    if (_state.availableUpdate == null) {
      return;
    }
    _setState(_state.copyWith(availableUpdate: null));
  }

  Future<void> _checkForUpdate() async {
    final result = await _updateRepository.check();
    if (result case Success<AppVersionInfo?>(:final value) when value != null) {
      _setState(_state.copyWith(availableUpdate: value));
    }
  }

  Future<Result<void>> _refreshLibrary() async {
    _setState(
      _state.copyWith(
        playRecordsLoading: true,
        playRecordsError: null,
        favoritesLoading: true,
        favoritesError: null,
      ),
    );
    final results = await Future.wait(<Future<Result<void>>>[
      _loadPlayRecords(markLoading: false),
      _loadFavorites(markLoading: false),
    ]);
    final failure = results
        .map((result) => result.failureOrNull)
        .whereType<AppFailure>()
        .firstOrNull;
    return failure == null
        ? const Success<void>(null)
        : FailureResult<void>(failure);
  }

  Future<Result<void>> _refreshPlayRecordsOnly() => _loadPlayRecords();

  Future<Result<void>> _loadPlayRecords({bool markLoading = true}) async {
    if (markLoading) {
      _setState(
        _state.copyWith(playRecordsLoading: true, playRecordsError: null),
      );
    }
    try {
      final result = await _libraryRepository.getPlayRecords(
        forceRefresh: true,
      );
      final failure = result.failureOrNull;
      _setState(
        _state.copyWith(
          playRecords: result.valueOrNull ?? _state.playRecords,
          playRecordsLoading: false,
          playRecordsError: failure?.message,
        ),
      );
      return failure == null
          ? const Success<void>(null)
          : FailureResult<void>(failure);
    } catch (error, stackTrace) {
      const message = '刷新播放记录失败';
      _setState(
        _state.copyWith(playRecordsLoading: false, playRecordsError: message),
      );
      return FailureResult(
        AppFailure(
          kind: FailureKind.network,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> _refreshFavoritesOnly() => _loadFavorites();

  Future<Result<void>> _loadFavorites({bool markLoading = true}) async {
    if (markLoading) {
      _setState(_state.copyWith(favoritesLoading: true, favoritesError: null));
    }
    try {
      final result = await _libraryRepository.getFavorites(forceRefresh: true);
      final failure = result.failureOrNull;
      _setState(
        _state.copyWith(
          favorites: result.valueOrNull ?? _state.favorites,
          favoritesLoading: false,
          favoritesError: failure?.message,
        ),
      );
      return failure == null
          ? const Success<void>(null)
          : FailureResult<void>(failure);
    } catch (error, stackTrace) {
      const message = '刷新收藏夹失败';
      _setState(
        _state.copyWith(favoritesLoading: false, favoritesError: message),
      );
      return FailureResult(
        AppFailure(
          kind: FailureKind.network,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _warmSearchHistory() async {
    try {
      final result = await _libraryRepository.getSearchHistory(
        forceRefresh: true,
      );
      if (result case FailureResult(:final failure)) {
        AppLogger.debug('预刷新搜索历史失败', error: failure);
      }
    } catch (error, stackTrace) {
      AppLogger.debug('预刷新搜索历史异常', error: error, stackTrace: stackTrace);
    }
  }

  Future<Result<void>> _refreshContent() async {
    final sections = HomeRecommendationKind.values
        .map((kind) => kind.name)
        .toSet();
    _setState(
      _state.copyWith(
        loadingSections: sections,
        failedSections: _state.failedSections
            .where((section) => !sections.contains(section))
            .toSet(),
      ),
    );
    final results = await Future.wait(
      HomeRecommendationKind.values.map(
        (kind) => _loadRecommendation(kind, markLoading: false),
      ),
    );
    if (results.any((result) => result.isFailure)) {
      return FailureResult(
        AppFailure(kind: FailureKind.network, message: '部分首页内容加载失败'),
      );
    }
    return const Success<void>(null);
  }

  Future<Result<void>> _refreshRecommendation(HomeRecommendationKind kind) =>
      _loadRecommendation(kind);

  Future<Result<void>> _loadRecommendation(
    HomeRecommendationKind kind, {
    bool markLoading = true,
  }) async {
    final section = kind.name;
    if (markLoading) {
      _setState(
        _state.copyWith(
          loadingSections: <String>{..._state.loadingSections, section},
          failedSections: _state.failedSections
              .where((item) => item != section)
              .toSet(),
        ),
      );
    }

    try {
      final Result<List<DoubanMovie>>? catalogResult;
      final Result<List<BangumiItem>>? animeResult;
      if (kind == HomeRecommendationKind.anime) {
        catalogResult = null;
        animeResult = await _animeRepository.getTodayCalendar();
      } else {
        final catalogType = switch (kind) {
          HomeRecommendationKind.movie => CatalogType.movie,
          HomeRecommendationKind.tv => CatalogType.tv,
          HomeRecommendationKind.show => CatalogType.show,
          HomeRecommendationKind.anime => throw StateError('unreachable'),
        };
        catalogResult = await _catalogRepository.fetchHot(catalogType);
        animeResult = null;
      }

      final failure =
          catalogResult?.failureOrNull ?? animeResult?.failureOrNull;
      _completeRecommendation(
        kind: kind,
        catalogItems: catalogResult?.valueOrNull,
        animeItems: animeResult?.valueOrNull,
        failure: failure,
      );
      return failure == null
          ? const Success<void>(null)
          : FailureResult<void>(failure);
    } catch (error, stackTrace) {
      final failure = AppFailure(
        kind: FailureKind.network,
        message: kind == HomeRecommendationKind.anime
            ? '加载 Bangumi 日历失败'
            : '加载热门内容失败',
        cause: error,
        stackTrace: stackTrace,
      );
      _completeRecommendation(kind: kind, failure: failure);
      return FailureResult<void>(failure);
    }
  }

  void _completeRecommendation({
    required HomeRecommendationKind kind,
    List<DoubanMovie>? catalogItems,
    List<BangumiItem>? animeItems,
    AppFailure? failure,
  }) {
    final section = kind.name;
    final failedSections = <String>{..._state.failedSections};
    if (failure == null) {
      failedSections.remove(section);
    } else {
      failedSections.add(section);
    }
    final loadingSections = <String>{..._state.loadingSections}
      ..remove(section);
    final videos = catalogItems
        ?.map((item) => item.toVideoInfo())
        .toList(growable: false);

    _setState(
      _state.copyWith(
        hotMovies: kind == HomeRecommendationKind.movie && videos != null
            ? videos
            : _state.hotMovies,
        hotTvShows: kind == HomeRecommendationKind.tv && videos != null
            ? videos
            : _state.hotTvShows,
        hotShows: kind == HomeRecommendationKind.show && videos != null
            ? videos
            : _state.hotShows,
        todayAnime:
            animeItems
                ?.map((item) => item.toVideoInfo())
                .toList(growable: false) ??
            _state.todayAnime,
        failedSections: failedSections,
        loadingSections: loadingSections,
      ),
    );
  }

  Future<Result<void>> _deleteRecord(PlayRecord record) async {
    final result = await _libraryRepository.deletePlayRecord(
      record.source,
      record.id,
    );
    if (result.isSuccess) {
      _setState(
        _state.copyWith(
          playRecords: _state.playRecords
              .where(
                (item) => item.source != record.source || item.id != record.id,
              )
              .toList(growable: false),
        ),
      );
      return const Success<void>(null);
    }
    return FailureResult(
      AppFailure(
        kind: FailureKind.network,
        message: result.failureOrNull?.message ?? '删除播放记录失败',
      ),
    );
  }

  Future<Result<void>> _addFavorite(PlayRecord record) async {
    final result = await _libraryRepository
        .addFavorite(record.source, record.id, <String, Object?>{
          'cover': record.cover,
          'save_time': DateTime.now().millisecondsSinceEpoch,
          'source_name': record.sourceName,
          'title': record.title,
          'total_episodes': record.totalEpisodes,
          'year': record.year,
        });
    if (result.isSuccess) {
      await _reloadFavoritesAfterMutation();
      return const Success<void>(null);
    }
    return FailureResult(
      AppFailure(
        kind: FailureKind.network,
        message: result.failureOrNull?.message ?? '收藏失败',
      ),
    );
  }

  Future<Result<void>> _removeFavorite(PlayRecord record) async {
    final result = await _libraryRepository.removeFavorite(
      record.source,
      record.id,
    );
    if (result.isSuccess) {
      _setState(
        _state.copyWith(
          favorites: _state.favorites
              .where(
                (item) => item.source != record.source || item.id != record.id,
              )
              .toList(growable: false),
        ),
      );
      return const Success<void>(null);
    }
    return FailureResult(
      AppFailure(
        kind: FailureKind.network,
        message: result.failureOrNull?.message ?? '取消收藏失败',
      ),
    );
  }

  Future<Result<void>> _clearRecords() async {
    final result = await _libraryRepository.clearPlayRecords();
    if (result.isSuccess) {
      _setState(_state.copyWith(playRecords: const <PlayRecord>[]));
      return const Success<void>(null);
    }
    return FailureResult(
      AppFailure(
        kind: FailureKind.network,
        message: result.failureOrNull?.message ?? '清空播放记录失败',
      ),
    );
  }

  Future<void> _reloadFavoritesAfterMutation() async {
    await _loadFavorites(markLoading: false);
  }

  Future<Result<void>> _dismissUpdate(String version) {
    return _updateRepository.dismiss(version);
  }

  void _setState(HomeUiState value) =>
      updateState(_state, value, (next) => _state = next);

  void _notifyCommandChanged() => notifyIfActive();

  @override
  void dispose() {
    _updateTimer?.cancel();
    refreshLibrary
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    refreshPlayRecords
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    refreshFavorites
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    refreshContent
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    refreshRecommendation
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    deleteRecord
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    addFavorite
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    removeFavorite
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    clearRecords
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    dismissUpdate
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    super.dispose();
  }
}
