import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:selene/data/repositories/anime_repository.dart';
import 'package:selene/data/repositories/catalog_repository.dart';
import 'package:selene/data/repositories/theme_repository.dart';
import 'package:selene/domain/models/anime_catalog.dart';
import 'package:selene/domain/models/bangumi.dart';
import 'package:selene/domain/models/catalog.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/domain/models/app_theme_mode.dart';
import 'package:selene/ui/catalog/view_models/anime_view_model.dart';
import 'package:selene/ui/catalog/view_models/catalog_view_model.dart';
import 'package:selene/ui/catalog/widgets/anime_screen.dart';
import 'package:selene/ui/catalog/widgets/catalog_screen.dart';
import 'package:selene/ui/core/layout/poster_grid_metrics.dart';
import 'package:selene/ui/core/view_models/theme_view_model.dart';
import 'package:selene/ui/core/utils/scroll_prefetch_policy.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('目录按内容类型保留上映与首播文案', () {
    expect(
      CatalogDefinition.movie.sortOptions
          .singleWhere((option) => option.value == 'R')
          .label,
      '上映时间',
    );
    expect(
      CatalogDefinition.tv.sortOptions
          .singleWhere((option) => option.value == 'R')
          .label,
      '首播时间',
    );
    expect(
      AnimeCatalogDefinition.series.sortOptions
          .singleWhere((option) => option.value == 'R')
          .label,
      '首播时间',
    );
    expect(
      AnimeCatalogDefinition.movie.sortOptions
          .singleWhere((option) => option.value == 'R')
          .label,
      '上映时间',
    );
    expect(
      () => AnimeCatalogDefinition.forType(AnimeCatalogType.calendar),
      throwsArgumentError,
    );
  });

  test('目录筛选配置保持各内容类型原有选项和顺序', () {
    expect(CatalogDefinition.movie.countSuffix, '部电影');
    expect(CatalogDefinition.tv.countSuffix, '部电视剧');
    expect(CatalogDefinition.show.countSuffix, '档综艺');
    expect(
      CatalogDefinition.movie.regionOptions.map((option) => option.label),
      const <String>[
        '全部',
        '华语',
        '欧美',
        '韩国',
        '日本',
        '中国大陆',
        '美国',
        '中国香港',
        '中国台湾',
        '英国',
        '法国',
        '德国',
        '意大利',
        '西班牙',
        '印度',
        '泰国',
        '俄罗斯',
        '加拿大',
        '澳大利亚',
        '爱尔兰',
        '瑞典',
        '巴西',
        '丹麦',
      ],
    );
    expect(
      AnimeCatalogDefinition.series.typeOptions.map((option) => option.label),
      const <String>[
        '全部',
        '黑色幽默',
        '历史',
        '歌舞',
        '励志',
        '恶搞',
        '治愈',
        '运动',
        '后宫',
        '情色',
        '国漫',
        '人性',
        '悬疑',
        '恋爱',
        '魔幻',
        '科幻',
      ],
    );
    expect(
      AnimeCatalogDefinition.movie.typeOptions.map((option) => option.label),
      const <String>[
        '全部',
        '定格动画',
        '传记',
        '美国动画',
        '爱情',
        '黑色幽默',
        '歌舞',
        '儿童',
        '二次元',
        '动物',
        '青春',
        '历史',
        '励志',
        '恶搞',
        '治愈',
        '运动',
        '后宫',
        '情色',
        '人性',
        '悬疑',
        '恋爱',
        '魔幻',
        '科幻',
      ],
    );
    expect(
      AnimeCatalogDefinition.series.regionOptions,
      same(CatalogDefinition.tv.regionOptions),
    );
    expect(
      AnimeCatalogDefinition.movie.regionOptions,
      same(CatalogDefinition.movie.regionOptions),
    );
  });

  test('目录分页按视口和真实网格行高响应式预取', () {
    final phoneGrid = PosterGridMetrics.calculate(
      availableWidth: 390,
      crossAxisCount: 3,
      isTablet: false,
    );
    final tabletGrid = PosterGridMetrics.calculate(
      availableWidth: 1200,
      crossAxisCount: 8,
      isTablet: true,
    );

    final phoneThreshold = ScrollPrefetchPolicy.calculateThreshold(
      viewportExtent: 780,
      rowExtent: phoneGrid.rowExtent,
    );
    final tabletThreshold = ScrollPrefetchPolicy.calculateThreshold(
      viewportExtent: 900,
      rowExtent: tabletGrid.rowExtent,
    );

    expect(phoneThreshold, greaterThanOrEqualTo(phoneGrid.rowExtent));
    expect(phoneThreshold, lessThanOrEqualTo(780));
    expect(tabletThreshold, greaterThanOrEqualTo(tabletGrid.rowExtent));
    expect(tabletThreshold, lessThanOrEqualTo(900));
    expect(phoneThreshold, isNot(tabletThreshold));
    expect(
      ScrollPrefetchPolicy.calculateThreshold(
        viewportExtent: 1000,
        rowExtent: 600,
      ),
      600,
    );
    expect(
      ScrollPrefetchPolicy.calculateThreshold(
        viewportExtent: 300,
        rowExtent: 400,
      ),
      300,
    );
    expect(
      ScrollPrefetchPolicy.shouldPrefetch(
        extentAfter: phoneThreshold,
        viewportExtent: 780,
        rowExtent: phoneGrid.rowExtent,
        isLoading: false,
        hasMore: true,
      ),
      isTrue,
    );
    expect(
      ScrollPrefetchPolicy.shouldPrefetch(
        extentAfter: phoneThreshold + 1,
        viewportExtent: 780,
        rowExtent: phoneGrid.rowExtent,
        isLoading: false,
        hasMore: true,
      ),
      isFalse,
    );
    expect(
      ScrollPrefetchPolicy.shouldPrefetch(
        extentAfter: 0,
        viewportExtent: 780,
        rowExtent: phoneGrid.rowExtent,
        isLoading: true,
        hasMore: true,
      ),
      isFalse,
    );
    expect(
      ScrollPrefetchPolicy.shouldPrefetch(
        extentAfter: 0,
        viewportExtent: 780,
        rowExtent: phoneGrid.rowExtent,
        isLoading: false,
        hasMore: false,
      ),
      isFalse,
    );
  });

  testWidgets('电影目录保留分类筛选和类型化上映时间文案', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        CatalogScreen(
          viewModel: CatalogViewModel(
            repository: _EmptyCatalogRepository(),
            definition: CatalogDefinition.movie,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('电影'), findsWidgets);
    expect(find.text('热门电影'), findsOneWidget);
  });

  testWidgets('目录子页面卸载后不销毁父级拥有的 ViewModel', (tester) async {
    final viewModel = CatalogViewModel(
      repository: _EmptyCatalogRepository(),
      definition: CatalogDefinition.movie,
    );
    void listener() {}

    await tester.pumpWidget(_testApp(CatalogScreen(viewModel: viewModel)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(() => viewModel.addListener(listener), returnsNormally);
    viewModel
      ..removeListener(listener)
      ..dispose();
  });

  testWidgets('动漫子页面卸载后不销毁父级拥有的 ViewModel', (tester) async {
    final viewModel = AnimeViewModel(repository: _EmptyAnimeRepository());
    void listener() {}

    await tester.pumpWidget(_testApp(AnimeScreen(viewModel: viewModel)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(() => viewModel.addListener(listener), returnsNormally);
    viewModel
      ..removeListener(listener)
      ..dispose();
  });

  testWidgets('目录快速滚动进入响应式阈值后慢请求只触发一次', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ControlledPagedCatalogRepository();

    await tester.pumpWidget(
      _testApp(
        CatalogScreen(
          viewModel: CatalogViewModel(
            repository: repository,
            definition: CatalogDefinition.movie,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.fetches, 1);

    final scrollFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.controller != null &&
          widget.scrollDirection == Axis.vertical,
    );
    final scrollView = tester.widget<SingleChildScrollView>(scrollFinder);
    final controller = scrollView.controller!;
    final grid = PosterGridMetrics.calculate(
      availableWidth: 1200,
      crossAxisCount: 8,
      isTablet: true,
    );
    final threshold = ScrollPrefetchPolicy.calculateThreshold(
      viewportExtent: controller.position.viewportDimension,
      rowExtent: grid.rowExtent,
    );

    controller.jumpTo(controller.position.maxScrollExtent - threshold - 1);
    await tester.pump();
    expect(repository.fetches, 1);

    controller.jumpTo(controller.position.maxScrollExtent - threshold + 1);
    await tester.pump();
    expect(repository.fetches, 2);

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(repository.fetches, 2);

    repository.completeNextPage();
    await tester.pumpAndSettle();
  });

  testWidgets('动漫目录保留每日放送、番剧和剧场版入口', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        AnimeScreen(
          viewModel: AnimeViewModel(repository: _EmptyAnimeRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('每日放送'), findsWidgets);
    expect(find.text('番剧'), findsOneWidget);
    expect(find.text('剧场版'), findsOneWidget);
  });

  testWidgets('动漫到底提示保持分隔线和两行原有文案', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        AnimeScreen(viewModel: AnimeViewModel(repository: _AnimeRepository())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已经到底啦~'), findsOneWidget);
    expect(find.text('共 1 部番剧'), findsOneWidget);
  });
}

Widget _testApp(Widget home) => ChangeNotifierProvider<ThemeViewModel>(
  create: (_) => ThemeViewModel(repository: _FakeThemeRepository()),
  child: MaterialApp(home: home),
);

final class _FakeThemeRepository extends ChangeNotifier
    implements ThemeRepository {
  @override
  AppThemeMode get mode => AppThemeMode.light;
  @override
  bool get isDark => false;
  @override
  Future<void> setMode(AppThemeMode mode) async {}
}

final class _EmptyCatalogRepository implements CatalogRepository {
  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) async =>
      const Success<List<DoubanMovie>>(<DoubanMovie>[]);

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async =>
      const Success<List<DoubanMovie>>(<DoubanMovie>[]);
}

final class _ControlledPagedCatalogRepository implements CatalogRepository {
  final Completer<Result<List<DoubanMovie>>> _nextPage = Completer();
  int fetches = 0;

  void completeNextPage() {
    _nextPage.complete(const Success<List<DoubanMovie>>(<DoubanMovie>[]));
  }

  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) {
    fetches++;
    if (fetches > 1) return _nextPage.future;
    return Future.value(
      Success<List<DoubanMovie>>(
        List<DoubanMovie>.generate(
          48,
          (index) => DoubanMovie(
            id: 'movie-$index',
            title: '电影 $index',
            poster: '',
            year: '2026',
          ),
        ),
      ),
    );
  }

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async =>
      const Success<List<DoubanMovie>>(<DoubanMovie>[]);
}

class _EmptyAnimeRepository implements AnimeRepository {
  @override
  Future<Result<List<BangumiItem>>> getTodayCalendar() async =>
      const Success<List<BangumiItem>>(<BangumiItem>[]);

  @override
  Future<Result<List<BangumiItem>>> getCalendar(int weekday) async =>
      const Success<List<BangumiItem>>(<BangumiItem>[]);

  @override
  Future<Result<List<DoubanMovie>>> getCatalog(AnimeCatalogQuery query) async =>
      const Success<List<DoubanMovie>>(<DoubanMovie>[]);
}

final class _AnimeRepository extends _EmptyAnimeRepository {
  static const _items = <BangumiItem>[
    BangumiItem(
      id: 1,
      url: '',
      type: 2,
      name: '测试番剧',
      summary: '',
      airDate: '2026-07-25',
      airWeekday: 6,
      rating: BangumiRating(total: 0, count: <String, int>{}, score: 0),
      rank: 0,
      images: BangumiImages(
        large: '',
        common: '',
        medium: '',
        small: '',
        grid: '',
      ),
      collection: BangumiCollection(doing: 0),
    ),
  ];

  @override
  Future<Result<List<BangumiItem>>> getTodayCalendar() async =>
      const Success<List<BangumiItem>>(_items);

  @override
  Future<Result<List<BangumiItem>>> getCalendar(int weekday) async =>
      const Success<List<BangumiItem>>(_items);
}
