import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:selene/data/repositories/theme_repository.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/data/repositories/anime_repository.dart';
import 'package:selene/data/repositories/catalog_repository.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/domain/models/app_theme_mode.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/domain/models/anime_catalog.dart';
import 'package:selene/domain/models/bangumi.dart';
import 'package:selene/domain/models/catalog.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/domain/models/favorite_item.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/ui/home/view_models/home_view_model.dart';
import 'package:selene/ui/home/widgets/home_recommendation_section.dart';
import 'package:selene/ui/core/view_models/theme_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('HomeViewModel', () {
    test('导航状态只由 ViewModel 更新', () {
      final viewModel = HomeViewModel(
        libraryRepository: _FakeLibraryRepository(),
        catalogRepository: _FakeCatalogRepository(),
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      viewModel
        ..selectBottomNavigation(3)
        ..selectTopTab(2);

      expect(viewModel.state.bottomNavigationIndex, 3);
      expect(viewModel.state.topTabIndex, 2);

      viewModel.selectHome();
      expect(viewModel.state.bottomNavigationIndex, 0);
      expect(viewModel.state.topTabIndex, 0);
      viewModel.dispose();
    });

    test('初始化统一刷新三类个人资料并公开可用更新', () async {
      final library = _FakeLibraryRepository();
      final update = _FakeUpdateRepository(
        available: AppVersionInfo(
          currentVersion: '1.0.0',
          latestVersion: '1.1.0',
          releaseNotes: 'notes',
          releaseUri: Uri.parse('https://example.com/v1.1.0'),
        ),
      );
      final viewModel = HomeViewModel(
        libraryRepository: library,
        catalogRepository: _FakeCatalogRepository(),
        animeRepository: _FakeAnimeRepository(),
        updateRepository: update,
        updateDelay: Duration.zero,
      );

      viewModel.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(library.playRecordReads, 1);
      expect(library.favoriteReads, 1);
      expect(library.searchHistoryRefreshes, 1);
      expect(viewModel.state.playRecords, library.records);
      expect(viewModel.state.favorites, library.favorites);
      expect(viewModel.state.availableUpdate?.latestVersion, '1.1.0');
      viewModel.dispose();
    });

    test('播放记录与收藏并发加载且各自完成后立即更新', () async {
      final library = _ControlledLibraryRepository();
      final viewModel = HomeViewModel(
        libraryRepository: library,
        catalogRepository: _FakeCatalogRepository(),
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      final refresh = viewModel.refreshLibrary.execute();
      await Future<void>.delayed(Duration.zero);
      final requestsStartedTogether =
          library.playRecordReads == 1 && library.favoriteReads == 1;

      library.completePlayRecords(<PlayRecord>[
        PlayRecord(
          id: 'record',
          source: 'source',
          title: '已完成的播放记录',
          sourceName: 'source',
          year: '2026',
          cover: '',
          index: 1,
          totalEpisodes: 1,
          playTime: 0,
          totalTime: 0,
          saveTime: 1,
          searchTitle: '已完成的播放记录',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      final recordVisibleBeforeFavorites =
          viewModel.state.playRecords.singleOrNull?.id == 'record';

      library.completeFavorites(const <FavoriteItem>[]);
      await refresh;

      expect(requestsStartedTogether, isTrue);
      expect(recordVisibleBeforeFavorites, isTrue);
      viewModel.dispose();
    });

    test('收藏失败不会污染播放记录区域状态', () async {
      final library = _ControlledLibraryRepository();
      final viewModel = HomeViewModel(
        libraryRepository: library,
        catalogRepository: _FakeCatalogRepository(),
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      final refresh = viewModel.refreshLibrary.execute();
      await Future<void>.delayed(Duration.zero);
      library
        ..completePlayRecords(<PlayRecord>[
          PlayRecord(
            id: 'record',
            source: 'source',
            title: '播放记录',
            sourceName: 'source',
            year: '2026',
            cover: '',
            index: 1,
            totalEpisodes: 1,
            playTime: 0,
            totalTime: 0,
            saveTime: 1,
            searchTitle: '播放记录',
          ),
        ])
        ..failFavorites();
      await refresh;

      expect(viewModel.state.playRecordsError, isNull);
      expect(viewModel.state.playRecords.single.id, 'record');
      expect(viewModel.state.favoritesError, '刷新收藏夹失败');
      viewModel.dispose();
    });

    test('个人资料写操作由 Command 串行封装', () async {
      final library = _FakeLibraryRepository();
      final viewModel = HomeViewModel(
        libraryRepository: library,
        catalogRepository: _FakeCatalogRepository(),
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );
      final record = PlayRecord(
        id: 'id',
        source: 'source',
        title: 'title',
        sourceName: 'sourceName',
        year: '2026',
        cover: '',
        index: 1,
        totalEpisodes: 1,
        playTime: 0,
        totalTime: 0,
        saveTime: 1,
        searchTitle: 'title',
      );

      final result = await viewModel.deleteRecord.execute(record);

      expect(result, isA<Success<void>>());
      expect(library.deletedSource, record.source);
      expect(library.deletedId, record.id);
      viewModel.dispose();
    });

    test('播放记录与收藏局部刷新不触发无关请求', () async {
      final library = _FakeLibraryRepository();
      final viewModel = HomeViewModel(
        libraryRepository: library,
        catalogRepository: _FakeCatalogRepository(),
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      await viewModel.refreshPlayRecords.execute();
      expect(library.playRecordReads, 1);
      expect(library.favoriteReads, 0);

      await viewModel.refreshFavorites.execute();
      expect(library.playRecordReads, 1);
      expect(library.favoriteReads, 1);
      viewModel.dispose();
    });

    test('单个推荐区块重试只请求对应内容', () async {
      final catalog = _FakeCatalogRepository();
      final anime = _FakeAnimeRepository();
      final viewModel = HomeViewModel(
        libraryRepository: _FakeLibraryRepository(),
        catalogRepository: catalog,
        animeRepository: anime,
        updateRepository: _FakeUpdateRepository(),
      );

      await viewModel.refreshRecommendation.execute(HomeRecommendationKind.tv);

      expect(catalog.movieFetches, 0);
      expect(catalog.tvFetches, 1);
      expect(catalog.showFetches, 0);
      expect(anime.calendarFetches, 0);
      viewModel.dispose();
    });

    test('全量刷新保持旧版各推荐区块完成后立即显示', () async {
      final catalog = _ControlledCatalogRepository();
      final viewModel = HomeViewModel(
        libraryRepository: _FakeLibraryRepository(),
        catalogRepository: catalog,
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      final refresh = viewModel.refreshContent.execute();
      await Future<void>.delayed(Duration.zero);
      catalog.complete(CatalogType.movie, const <DoubanMovie>[
        DoubanMovie(id: 'movie', title: '已完成的电影', poster: '', year: '2026'),
      ]);
      await Future<void>.delayed(Duration.zero);
      final movieVisibleBeforeOtherSections =
          viewModel.state.hotMovies.singleOrNull?.title == '已完成的电影';

      catalog
        ..complete(CatalogType.tv, const <DoubanMovie>[])
        ..complete(CatalogType.show, const <DoubanMovie>[]);
      await refresh;

      expect(movieVisibleBeforeOtherSections, isTrue);
      viewModel.dispose();
    });

    testWidgets('已有数据重试时保留内容并显示非阻断状态', (tester) async {
      final catalog = _ControlledCatalogRepository();
      final viewModel = HomeViewModel(
        libraryRepository: _FakeLibraryRepository(),
        catalogRepository: catalog,
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      final initialRefresh = viewModel.refreshContent.execute();
      await tester.pump();
      catalog
        ..complete(CatalogType.movie, const <DoubanMovie>[
          DoubanMovie(id: 'movie', title: '已有电影', poster: '', year: '2026'),
        ])
        ..complete(CatalogType.tv, const <DoubanMovie>[])
        ..complete(CatalogType.show, const <DoubanMovie>[]);
      await initialRefresh;

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel(repository: _FakeThemeRepository()),
          child: MaterialApp(
            home: Scaffold(
              body: HomeRecommendationSection(
                viewModel: viewModel,
                kind: HomeRecommendationKind.movie,
                onItemTap: (_) {},
                onMoreTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('已有电影'), findsOneWidget);

      final retry = viewModel.refreshRecommendation.execute(
        HomeRecommendationKind.movie,
      );
      await tester.pump();
      expect(find.text('已有电影'), findsOneWidget);
      expect(find.text('刷新中…'), findsOneWidget);

      catalog.fail(CatalogType.movie);
      await retry;
      await tester.pump();
      expect(find.text('已有电影'), findsOneWidget);
      expect(find.text('刷新失败'), findsOneWidget);
      expect(find.text('加载失败'), findsNothing);

      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(find.text('已有电影'), findsOneWidget);
      expect(find.text('刷新中…'), findsOneWidget);
      catalog.complete(CatalogType.movie, const <DoubanMovie>[
        DoubanMovie(id: 'new-movie', title: '刷新后的电影', poster: '', year: '2026'),
      ]);
      await tester.pump();
      expect(find.text('刷新后的电影'), findsOneWidget);
      expect(find.text('刷新中…'), findsNothing);
      viewModel.dispose();
    });

    testWidgets('首次加载失败仍显示区块错误和重试入口', (tester) async {
      final catalog = _ControlledCatalogRepository();
      final viewModel = HomeViewModel(
        libraryRepository: _FakeLibraryRepository(),
        catalogRepository: catalog,
        animeRepository: _FakeAnimeRepository(),
        updateRepository: _FakeUpdateRepository(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeViewModel>(
          create: (_) => ThemeViewModel(repository: _FakeThemeRepository()),
          child: MaterialApp(
            home: Scaffold(
              body: HomeRecommendationSection(
                viewModel: viewModel,
                kind: HomeRecommendationKind.movie,
                onItemTap: (_) {},
                onMoreTap: () {},
              ),
            ),
          ),
        ),
      );

      final refresh = viewModel.refreshRecommendation.execute(
        HomeRecommendationKind.movie,
      );
      await tester.pump();
      catalog.fail(CatalogType.movie);
      await refresh;
      await tester.pump();

      expect(find.text('热门电影'), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      viewModel.dispose();
    });
  });
}

final class _ControlledLibraryRepository implements LibraryRepository {
  final _playRecords = Completer<Result<List<PlayRecord>>>();
  final _favorites = Completer<Result<List<FavoriteItem>>>();
  int playRecordReads = 0;
  int favoriteReads = 0;

  void completePlayRecords(List<PlayRecord> records) {
    _playRecords.complete(Success<List<PlayRecord>>(records));
  }

  void completeFavorites(List<FavoriteItem> favorites) {
    _favorites.complete(Success<List<FavoriteItem>>(favorites));
  }

  void failFavorites() {
    _favorites.complete(
      const FailureResult<List<FavoriteItem>>(
        AppFailure(kind: FailureKind.network, message: '刷新收藏夹失败'),
      ),
    );
  }

  @override
  Future<Result<List<PlayRecord>>> getPlayRecords({bool forceRefresh = false}) {
    playRecordReads++;
    return _playRecords.future;
  }

  @override
  Future<Result<List<FavoriteItem>>> getFavorites({bool forceRefresh = false}) {
    favoriteReads++;
    return _favorites.future;
  }

  @override
  Future<Result<List<String>>> getSearchHistory({
    bool forceRefresh = false,
  }) async => const Success<List<String>>(<String>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledCatalogRepository implements CatalogRepository {
  final _requests = <CatalogType, Completer<Result<List<DoubanMovie>>>>{};

  void complete(CatalogType type, List<DoubanMovie> items) {
    _requests[type]!.complete(Success<List<DoubanMovie>>(items));
  }

  void fail(CatalogType type) {
    _requests[type]!.complete(
      const FailureResult<List<DoubanMovie>>(
        AppFailure(kind: FailureKind.network, message: '加载失败'),
      ),
    );
  }

  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) async =>
      const Success(<DoubanMovie>[]);

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) {
    final completer = Completer<Result<List<DoubanMovie>>>();
    _requests[type] = completer;
    return completer.future;
  }
}

final class _FakeThemeRepository extends ChangeNotifier
    implements ThemeRepository {
  @override
  AppThemeMode get mode => AppThemeMode.light;

  @override
  bool get isDark => false;

  @override
  Future<void> setMode(AppThemeMode mode) async {}
}

final class _FakeCatalogRepository implements CatalogRepository {
  int movieFetches = 0;
  int tvFetches = 0;
  int showFetches = 0;

  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) async =>
      const Success(<DoubanMovie>[]);

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async {
    switch (type) {
      case CatalogType.movie:
        movieFetches++;
      case CatalogType.tv:
        tvFetches++;
      case CatalogType.show:
        showFetches++;
    }
    return const Success(<DoubanMovie>[]);
  }
}

final class _FakeAnimeRepository implements AnimeRepository {
  int calendarFetches = 0;

  @override
  Future<Result<List<BangumiItem>>> getTodayCalendar() async {
    calendarFetches++;
    return const Success(<BangumiItem>[]);
  }

  @override
  Future<Result<List<BangumiItem>>> getCalendar(int weekday) async =>
      const Success(<BangumiItem>[]);

  @override
  Future<Result<List<DoubanMovie>>> getCatalog(AnimeCatalogQuery query) async =>
      const Success(<DoubanMovie>[]);
}

final class _FakeLibraryRepository implements LibraryRepository {
  final List<PlayRecord> records = <PlayRecord>[];
  final List<FavoriteItem> favorites = <FavoriteItem>[];
  int playRecordReads = 0;
  int favoriteReads = 0;
  int searchHistoryRefreshes = 0;
  String? deletedSource;
  String? deletedId;

  @override
  Future<Result<List<PlayRecord>>> getPlayRecords({
    bool forceRefresh = false,
  }) async {
    playRecordReads++;
    return Success<List<PlayRecord>>(records);
  }

  @override
  Future<Result<List<FavoriteItem>>> getFavorites({
    bool forceRefresh = false,
  }) async {
    favoriteReads++;
    return Success<List<FavoriteItem>>(favorites);
  }

  @override
  Future<Result<List<String>>> getSearchHistory({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) searchHistoryRefreshes++;
    return const Success<List<String>>(<String>[]);
  }

  @override
  Future<Result<void>> deletePlayRecord(String source, String id) async {
    deletedSource = source;
    deletedId = id;
    return const Success<void>(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeUpdateRepository extends ChangeNotifier
    implements UpdateRepository {
  _FakeUpdateRepository({this.available});

  final AppVersionInfo? available;

  @override
  Future<Result<AppVersionInfo?>> check({
    bool respectPromptPolicy = true,
  }) async => Success(available);

  @override
  Future<Result<void>> dismiss(String version) async =>
      const Success<void>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
