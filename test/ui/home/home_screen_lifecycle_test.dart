import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:selene/data/repositories/anime_repository.dart';
import 'package:selene/data/repositories/auth_repository.dart';
import 'package:selene/data/repositories/cache_repository.dart';
import 'package:selene/data/repositories/catalog_repository.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/data/repositories/live_repository.dart';
import 'package:selene/data/repositories/search_repository.dart';
import 'package:selene/data/repositories/sse_search_repository.dart';
import 'package:selene/data/repositories/settings_repository.dart';
import 'package:selene/data/repositories/theme_repository.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/domain/models/anime_catalog.dart';
import 'package:selene/domain/models/app_settings.dart';
import 'package:selene/domain/models/app_theme_mode.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/domain/models/bangumi.dart';
import 'package:selene/domain/models/catalog.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/domain/models/epg_program.dart';
import 'package:selene/domain/models/favorite_item.dart';
import 'package:selene/domain/models/live_channel.dart';
import 'package:selene/domain/models/live_source.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/search_progress.dart';
import 'package:selene/domain/models/search_session_event.dart';
import 'package:selene/ui/catalog/view_models/anime_view_model.dart';
import 'package:selene/ui/catalog/view_models/catalog_view_model.dart';
import 'package:selene/ui/core/view_models/theme_view_model.dart';
import 'package:selene/ui/core/widgets/top_tab_switcher.dart';
import 'package:selene/ui/home/view_models/home_view_model.dart';
import 'package:selene/ui/home/widgets/home_screen.dart';
import 'package:selene/ui/live/view_models/live_view_model.dart';
import 'package:selene/ui/search/view_models/search_ui_state.dart';
import 'package:selene/ui/search/view_models/search_view_model.dart';
import 'package:selene/ui/search/widgets/search_result_agg_grid.dart';
import 'package:selene/ui/search/widgets/search_screen.dart';
import 'package:selene/ui/settings/view_models/settings_view_model.dart';
import 'package:selene/ui/shell/view_models/shell_view_model.dart';
import 'package:selene/ui/shell/widgets/main_layout.dart';
import 'package:selene/utils/result.dart';

void main() {
  testWidgets('父路由重建后首页内容和两级标签状态保持一致', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harnessKey = GlobalKey<_HomeHarnessState>();
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => _HomeHarness(key: harnessKey),
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('独立页面')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_testRouterApp(router));
    await tester.pumpAndSettle();

    final harness = harnessKey.currentState!;
    expect(find.text('保留的推荐'), findsOneWidget);
    expect(harness.homeViewModels, hasLength(1));
    expect(harness.settingsViewModels, hasLength(1));
    expect(harness.catalogViewModels, hasLength(3));
    expect(harness.animeViewModels, hasLength(1));
    expect(harness.liveViewModels, hasLength(1));
    expect(harness.shellViewModels, hasLength(1));

    unawaited(router.push<void>('/other'));
    await tester.pumpAndSettle();
    expect(find.text('独立页面'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('保留的推荐'), findsOneWidget);
    expect(harness.homeViewModels, hasLength(1));
    expect(harness.settingsViewModels, hasLength(1));
    expect(harness.catalogViewModels, hasLength(3));
    expect(harness.animeViewModels, hasLength(1));
    expect(harness.liveViewModels, hasLength(1));
    expect(harness.shellViewModels, hasLength(1));

    for (final index in <int>[3, 1, 4, 2, 5, 0]) {
      tester
          .widget<MainLayout>(find.byType(MainLayout))
          .onBottomNavChanged(index);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MainLayout>(find.byType(MainLayout))
            .currentBottomNavIndex,
        index,
      );
      expect(tester.takeException(), isNull);
    }

    for (final tab in <String>['播放历史', '收藏夹', '首页']) {
      tester
          .widget<TopTabSwitcher>(find.byType(TopTabSwitcher))
          .onTabChanged(tab);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TopTabSwitcher>(find.byType(TopTabSwitcher)).selectedTab,
        tab,
      );
      expect(tester.takeException(), isNull);
    }

    unawaited(router.push<void>('/other'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('保留的推荐'), findsOneWidget);
    expect(
      tester.widget<MainLayout>(find.byType(MainLayout)).currentBottomNavIndex,
      0,
    );
    expect(
      tester.widget<TopTabSwitcher>(find.byType(TopTabSwitcher)).selectedTab,
      '首页',
    );
    expect(harness.homeViewModels, hasLength(1));
    expect(harness.catalogViewModels, hasLength(3));
  });

  testWidgets('首页作用域统一拥有并释放全部页面 ViewModel', (tester) async {
    final harnessKey = GlobalKey<_HomeHarnessState>();
    await tester.pumpWidget(_testApp(_HomeHarness(key: harnessKey)));
    await tester.pumpAndSettle();

    final ownedViewModels = harnessKey.currentState!.ownedViewModels;
    expect(ownedViewModels, hasLength(8));
    for (final viewModel in ownedViewModels) {
      expect(() => viewModel.addListener(_noop), returnsNormally);
      viewModel.removeListener(_noop);
    }

    await tester.pumpWidget(const SizedBox.shrink());

    expect(tester.takeException(), isNull);
    for (final viewModel in ownedViewModels) {
      expect(() => viewModel.addListener(_noop), throwsFlutterError);
    }
  });

  testWidgets('搜索路由释放自有 ViewModel 且不释放借用的设置 ViewModel', (tester) async {
    final harness = _SearchHarness();

    await tester.pumpWidget(_testApp(harness.screen));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(tester.takeException(), isNull);
    expect(
      () => harness.searchViewModel.addListener(_noop),
      throwsFlutterError,
    );
    expect(() => harness.shellViewModel.addListener(_noop), throwsFlutterError);
    expect(harness.searchSession.disposed, isTrue);
    expect(() => harness.settingsViewModel.addListener(_noop), returnsNormally);
    harness.settingsViewModel
      ..removeListener(_noop)
      ..dispose();
    harness.authRepository.dispose();
  });

  testWidgets('搜索失败显示错误和重试而不是未找到结果', (tester) async {
    final harness = _SearchHarness();
    await tester.pumpWidget(_testApp(harness.screen));
    await tester.pumpAndSettle();

    await harness.searchViewModel.search('故障查询');
    harness.searchSession.emitProgress(
      const SearchProgress(
        totalSources: 1,
        completedSources: 1,
        isComplete: true,
        isFailure: true,
        error: '搜索连接意外结束，请重试',
      ),
    );
    await tester.pump();

    expect(find.text('搜索连接意外结束，请重试'), findsOneWidget);
    expect(find.text('搜索失败'), findsOneWidget);
    expect(find.text('未找到结果'), findsNothing);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(harness.searchSession.startedQueries, <String>['故障查询', '故障查询']);
    expect(harness.searchViewModel.state.status, SearchStatus.searching);
    expect(find.text('搜索连接意外结束，请重试'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    harness.disposeBorrowed();
  });

  testWidgets('明确成功且结果为空时仍显示未找到结果', (tester) async {
    final harness = _SearchHarness();
    await tester.pumpWidget(_testApp(harness.screen));
    await tester.pumpAndSettle();

    await harness.searchViewModel.search('真实空结果');
    harness.searchSession.emitProgress(
      const SearchProgress(
        totalSources: 1,
        completedSources: 1,
        isComplete: true,
      ),
    );
    await tester.pump();

    expect(find.text('未找到结果'), findsOneWidget);
    expect(find.text('搜索失败'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    harness.disposeBorrowed();
  });

  testWidgets('部分搜索源失败时保留结果并显示非阻断警告', (tester) async {
    final harness = _SearchHarness();
    await tester.pumpWidget(_testApp(harness.screen));
    await tester.pumpAndSettle();

    await harness.searchViewModel.search('部分结果');
    harness.searchSession
      ..emitResults(<SearchResult>[
        SearchResult(
          id: 'partial',
          title: '保留的搜索结果',
          poster: '',
          episodes: const <String>[],
          episodesTitles: const <String>[],
          source: 'available',
          sourceName: '可用源',
          year: '2025',
        ),
      ])
      ..emitProgress(
        const SearchProgress(
          totalSources: 2,
          completedSources: 2,
          isComplete: true,
          error: '部分搜索源失败，结果可能不完整',
        ),
      );
    await tester.pumpAndSettle();

    expect(find.text('部分搜索源失败，结果可能不完整'), findsOneWidget);
    expect(harness.searchViewModel.state.results, hasLength(1));
    expect(
      tester
          .widget<SearchResultAggGrid>(find.byType(SearchResultAggGrid))
          .results,
      hasLength(1),
    );
    expect(
      tester
          .widget<SearchResultAggGrid>(find.byType(SearchResultAggGrid))
          .results
          .single
          .title,
      '保留的搜索结果',
    );
    expect(find.text('搜索失败'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    harness.disposeBorrowed();
  });
}

void _noop() {}

Widget _testApp(Widget home) {
  return ChangeNotifierProvider<ThemeViewModel>(
    create: (_) => ThemeViewModel(repository: _FakeThemeRepository()),
    child: MaterialApp(home: home),
  );
}

Widget _testRouterApp(GoRouter router) {
  return ChangeNotifierProvider<ThemeViewModel>(
    create: (_) => ThemeViewModel(repository: _FakeThemeRepository()),
    child: MaterialApp.router(routerConfig: router),
  );
}

class _HomeHarness extends StatefulWidget {
  const _HomeHarness({super.key});

  @override
  State<_HomeHarness> createState() => _HomeHarnessState();
}

class _HomeHarnessState extends State<_HomeHarness> {
  final _libraryRepository = _FakeLibraryRepository();
  final _catalogRepository = _FakeCatalogRepository();
  final _animeRepository = _FakeAnimeRepository();
  final _updateRepository = _FakeUpdateRepository();
  final _authRepository = _FakeAuthRepository();
  final _settingsRepository = _FakeSettingsRepository();
  final _cacheRepository = _FakeCacheRepository();
  final _liveRepository = _FakeLiveRepository();
  final _searchRepository = _FakeSearchRepository();

  final homeViewModels = <HomeViewModel>[];
  final settingsViewModels = <SettingsViewModel>[];
  final catalogViewModels = <CatalogViewModel>[];
  final animeViewModels = <AnimeViewModel>[];
  final liveViewModels = <LiveViewModel>[];
  final shellViewModels = <ShellViewModel>[];

  List<ChangeNotifier> get ownedViewModels => <ChangeNotifier>[
    ...homeViewModels,
    ...settingsViewModels,
    ...catalogViewModels,
    ...animeViewModels,
    ...liveViewModels,
    ...shellViewModels,
  ];

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      homeViewModelFactory: () {
        final viewModel = HomeViewModel(
          libraryRepository: _libraryRepository,
          catalogRepository: _catalogRepository,
          animeRepository: _animeRepository,
          updateRepository: _updateRepository,
          updateDelay: const Duration(days: 1),
        );
        homeViewModels.add(viewModel);
        return viewModel;
      },
      settingsViewModelFactory: () {
        final viewModel = SettingsViewModel(
          authRepository: _authRepository,
          settingsRepository: _settingsRepository,
          updateRepository: _updateRepository,
          cacheRepository: _cacheRepository,
          libraryRepository: _libraryRepository,
          liveRepository: _liveRepository,
        );
        settingsViewModels.add(viewModel);
        return viewModel;
      },
      searchViewModelFactory: () => throw UnimplementedError(),
      liveViewModelFactory: () {
        final viewModel = LiveViewModel(repository: _liveRepository);
        liveViewModels.add(viewModel);
        return viewModel;
      },
      livePlayerViewModelFactory: (_, _) => throw UnimplementedError(),
      catalogViewModelFactory: (definition) {
        final viewModel = CatalogViewModel(
          repository: _catalogRepository,
          definition: definition,
        );
        catalogViewModels.add(viewModel);
        return viewModel;
      },
      animeViewModelFactory: () {
        final viewModel = AnimeViewModel(repository: _animeRepository);
        animeViewModels.add(viewModel);
        return viewModel;
      },
      shellViewModelFactory: () {
        final viewModel = ShellViewModel(
          searchRepository: _searchRepository,
          settingsRepository: _settingsRepository,
        );
        shellViewModels.add(viewModel);
        return viewModel;
      },
    );
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
  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) async =>
      const Success(<DoubanMovie>[]);

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async {
    if (type == CatalogType.movie) {
      return const Success(<DoubanMovie>[
        DoubanMovie(id: 'retained', title: '保留的推荐', poster: '', year: '2026'),
      ]);
    }
    return const Success(<DoubanMovie>[]);
  }
}

final class _FakeAnimeRepository implements AnimeRepository {
  @override
  Future<Result<List<BangumiItem>>> getTodayCalendar() async =>
      const Success(<BangumiItem>[]);

  @override
  Future<Result<List<BangumiItem>>> getCalendar(int weekday) async =>
      const Success(<BangumiItem>[]);

  @override
  Future<Result<List<DoubanMovie>>> getCatalog(AnimeCatalogQuery query) async =>
      const Success(<DoubanMovie>[]);
}

final class _FakeLibraryRepository implements LibraryRepository {
  @override
  Future<Result<List<PlayRecord>>> getPlayRecords({
    bool forceRefresh = false,
  }) async => const Success(<PlayRecord>[]);

  @override
  Future<Result<List<FavoriteItem>>> getFavorites({
    bool forceRefresh = false,
  }) async => const Success(<FavoriteItem>[]);

  @override
  Future<Result<List<String>>> getSearchHistory({
    bool forceRefresh = false,
  }) async => const Success(<String>[]);

  @override
  Future<Result<void>> addSearchHistory(String query) async =>
      const Success<void>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeUpdateRepository extends ChangeNotifier
    implements UpdateRepository {
  @override
  Future<Result<AppVersionInfo?>> check({
    bool respectPromptPolicy = true,
  }) async => const Success<AppVersionInfo?>(null);

  @override
  Future<Result<void>> dismiss(String version) async =>
      const Success<void>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeAuthRepository extends ChangeNotifier
    implements AuthRepository {
  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  AuthProfile get profile => const AuthProfile(username: 'tester');

  @override
  String get role => 'user';

  @override
  String? get message => null;

  @override
  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Result<AppSettings>> load() async =>
      const Success<AppSettings>(AppSettings());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeCacheRepository implements CacheRepository {
  @override
  void clearSearchCache() {}

  @override
  Future<Result<void>> clearCatalogAndSearch() async =>
      const Success<void>(null);

  @override
  void dispose() {}
}

final class _FakeLiveRepository implements LiveRepository {
  @override
  Future<Result<List<LiveSource>>> getLiveSources({
    bool forceRefresh = false,
  }) async => const Success(<LiveSource>[]);

  @override
  Future<Result<List<LiveChannel>>> getLiveChannels(
    String sourceKey, {
    bool forceRefresh = false,
  }) async => const Success(<LiveChannel>[]);

  @override
  Future<Result<EpgData?>> getLiveEpg(
    String tvgId,
    String sourceKey, {
    bool forceRefresh = false,
  }) async => const Success<EpgData?>(null);

  @override
  void clearAllCache() {}

  @override
  void clearAllChannelsAndEpgCache() {}

  @override
  void clearChannelsCache(String sourceKey) {}

  @override
  void clearEpgCache(String sourceKey) {}

  @override
  void clearSourcesCache() {}
}

final class _FakeSearchRepository implements SearchRepository {
  @override
  void clearCache() {}

  @override
  Future<Result<List<String>>> getSuggestions(
    String query, {
    required bool localSearchEnabled,
  }) async => const Success(<String>[]);

  @override
  Future<Result<List<SearchResult>>> getLocalDetail(
    String source,
    String id,
  ) async => const Success(<SearchResult>[]);

  @override
  Future<Result<List<SearchResult>>> searchLocal(String query) async =>
      const Success(<SearchResult>[]);

  @override
  Future<Result<List<String>>> searchRecommendations(String query) async =>
      const Success(<String>[]);
}

final class _FakeSearchSession implements SSESearchRepository {
  final _events = StreamController<SearchSessionEvent>.broadcast();
  final List<String> startedQueries = <String>[];
  bool disposed = false;

  void emitResults(List<SearchResult> results) =>
      _events.add(SearchSessionResults(results));

  void emitProgress(SearchProgress progress) =>
      _events.add(SearchSessionProgress(progress));

  @override
  Stream<SearchSessionEvent> get events => _events.stream;

  @override
  Future<void> startSearch(
    String query, {
    required bool localSearchEnabled,
  }) async => startedQueries.add(query);

  @override
  Future<void> stopSearch() async {}

  @override
  void dispose() {
    disposed = true;
    unawaited(_events.close());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _SearchHarness {
  final _FakeAuthRepository authRepository = _FakeAuthRepository();
  final _FakeSettingsRepository settingsRepository = _FakeSettingsRepository();
  final _FakeSearchSession searchSession = _FakeSearchSession();

  late final SettingsViewModel settingsViewModel = SettingsViewModel(
    authRepository: authRepository,
    settingsRepository: settingsRepository,
    updateRepository: _FakeUpdateRepository(),
    cacheRepository: _FakeCacheRepository(),
    libraryRepository: _FakeLibraryRepository(),
    liveRepository: _FakeLiveRepository(),
  );
  late final SearchViewModel searchViewModel = SearchViewModel(
    libraryRepository: _FakeLibraryRepository(),
    searchSession: searchSession,
    settingsRepository: settingsRepository,
  );
  late final ShellViewModel shellViewModel = ShellViewModel(
    searchRepository: _FakeSearchRepository(),
    settingsRepository: settingsRepository,
  );

  SearchScreen get screen => SearchScreen(
    viewModelFactory: () => searchViewModel,
    shellViewModelFactory: () => shellViewModel,
    settingsViewModel: settingsViewModel,
  );

  void disposeBorrowed() {
    settingsViewModel.dispose();
    authRepository.dispose();
  }
}
