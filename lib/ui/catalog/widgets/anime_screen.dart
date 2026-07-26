import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/anime_catalog.dart';
import '../../../domain/models/catalog.dart';
import '../../../domain/models/video_info.dart';
import '../../../routing/routes.dart';
import '../../../utils/device_utils.dart';
import '../../../utils/font_utils.dart';
import 'bangumi_grid.dart';
import 'capsule_tab_switcher.dart';
import 'douban_movies_grid.dart';
import 'simple_tab_switcher.dart';
import '../../core/layout/poster_grid_metrics.dart';
import '../../core/utils/scroll_prefetch_policy.dart';
import '../../core/widgets/custom_refresh_indicator.dart';
import '../../core/widgets/filter_options_selector.dart';
import '../../core/widgets/filter_pill_hover.dart';
import '../../core/widgets/pulsing_dots_indicator.dart';
import '../../core/widgets/video_menu_bottom_sheet.dart';
import '../view_models/anime_view_model.dart';

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key, required this.viewModel});

  /// 由首页作用域持有生命周期，本页面只订阅状态。
  final AnimeViewModel viewModel;

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastLoadedPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    widget.viewModel
      ..addListener(_handleViewModelChanged)
      ..initialize();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    widget.viewModel.removeListener(_handleViewModelChanged);
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    final state = widget.viewModel.state;
    final pageAdvanced = state.page > _lastLoadedPage;
    _lastLoadedPage = state.page;
    setState(() {});
    if (!pageAdvanced) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _tryLoadMore(_scrollController.position);
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    _tryLoadMore(_scrollController.position);
  }

  void _tryLoadMore(ScrollPosition position) {
    final state = widget.viewModel.state;
    if (state.category == '每日放送' || state.animeItems.isEmpty) return;

    final grid = PosterGridMetrics.calculate(
      availableWidth: MediaQuery.sizeOf(context).width,
      crossAxisCount: DeviceUtils.getTabletColumnCount(context),
      isTablet: DeviceUtils.isTablet(context),
    );
    if (ScrollPrefetchPolicy.shouldPrefetch(
      extentAfter: position.extentAfter,
      viewportExtent: position.viewportDimension,
      rowExtent: grid.rowExtent,
      isLoading: state.loading || state.loadingMore,
      hasMore: state.hasMore,
    )) {
      widget.viewModel.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.viewModel.state;
    return StyledRefreshIndicator(
      onRefresh: widget.viewModel.refresh,
      refreshText: '刷新动漫数据...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilters(),
            const SizedBox(height: 16),
            if (state.category == '每日放送')
              BangumiGrid(
                bangumiItems: state.calendarItems,
                isLoading: state.loading && state.calendarItems.isEmpty,
                errorMessage: state.error,
                onVideoTap: _openPlayer,
                onGlobalMenuAction: _handleMenuAction,
              )
            else
              DoubanMoviesGrid(
                movies: state.animeItems,
                isLoading: state.loading && state.animeItems.isEmpty,
                errorMessage: state.error,
                onVideoTap: _openPlayer,
                onGlobalMenuAction: _handleMenuAction,
                contentType: 'anime',
              ),
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: PulsingDotsIndicator(),
              )
            else if (!state.loading &&
                ((state.category == '每日放送' && state.calendarItems.isNotEmpty) ||
                    (!state.hasMore && state.animeItems.isNotEmpty)))
              _buildEndIndicator()
            else
              const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final calendar = widget.viewModel.state.category == '每日放送';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '动漫',
            style: FontUtils.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            calendar ? '来自 Bangumi 的精选内容' : '来自豆瓣的精选内容',
            style: FontUtils.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final state = widget.viewModel.state;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryRow(),
          const SizedBox(height: 16),
          SizedBox(
            height: 66,
            child: switch (state.category) {
              '每日放送' => _buildWeekdaySelector(),
              '番剧' => _buildAdvancedFilters(series: true),
              _ => _buildAdvancedFilters(series: false),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    final state = widget.viewModel.state;
    return _buildLabeledRow(
      '分类',
      CapsuleTabSwitcher(
        tabs: _categories.map((option) => option.label).toList(),
        selectedTab: state.category,
        onTabChanged: widget.viewModel.selectCategory,
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final state = widget.viewModel.state;
    return _buildLabeledRow(
      '星期',
      SimpleTabSwitcher(
        tabs: _weekdays.map((option) => option.label).toList(),
        selectedTab: _label(_weekdays, state.weekday),
        onTabChanged: (label) => widget.viewModel.selectWeekday(
          _weekdays.firstWhere((option) => option.label == label).value,
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters({required bool series}) {
    final state = widget.viewModel.state;
    final definition = series
        ? AnimeCatalogDefinition.series
        : AnimeCatalogDefinition.movie;
    return _buildLabeledRow(
      '筛选',
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _pill(
              '类型',
              definition.typeOptions,
              series ? state.animeType : state.movieType,
              series
                  ? widget.viewModel.selectAnimeType
                  : widget.viewModel.selectMovieType,
            ),
            _pill(
              '地区',
              definition.regionOptions,
              series ? state.animeRegion : state.movieRegion,
              series
                  ? widget.viewModel.selectAnimeRegion
                  : widget.viewModel.selectMovieRegion,
            ),
            _pill(
              '年代',
              definition.yearOptions,
              series ? state.animeYear : state.movieYear,
              series
                  ? widget.viewModel.selectAnimeYear
                  : widget.viewModel.selectMovieYear,
            ),
            if (series)
              _pill(
                '平台',
                definition.platformOptions,
                state.animePlatform,
                widget.viewModel.selectAnimePlatform,
              ),
            _pill(
              '排序',
              definition.sortOptions,
              series ? state.animeSort : state.movieSort,
              series
                  ? widget.viewModel.selectAnimeSort
                  : widget.viewModel.selectMovieSort,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledRow(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FontUtils.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(height: 36, child: child),
      ],
    );
  }

  Widget _pill(
    String title,
    List<CatalogFilterOption> options,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final selected = options.firstWhere(
      (option) => option.value == selectedValue,
      orElse: () => options.first,
    );
    return FilterPillHover(
      isPC: DeviceUtils.isPC(),
      isDefault:
          selectedValue == 'all' || (title == '排序' && selectedValue == 'T'),
      title: title,
      selectedOption: SelectorOption(
        label: selected.label,
        value: selected.value,
      ),
      onTap: () => showFilterOptionsSelector(
        context: context,
        title: title,
        options: options
            .map(
              (option) =>
                  SelectorOption(label: option.label, value: option.value),
            )
            .toList(),
        selectedValue: selectedValue,
        onSelected: onSelected,
      ),
    );
  }

  void _openPlayer(VideoInfo video) {
    PlayerRoute(
      title: video.title,
      year: video.year,
      stype: widget.viewModel.state.category == '剧场版' ? 'movie' : null,
    ).push<void>(context);
  }

  void _handleMenuAction(VideoInfo video, VideoMenuAction action) {
    if (action == VideoMenuAction.play) {
      _openPlayer(video);
    } else if (action == VideoMenuAction.doubanDetail) {
      _launchDouban(video.id);
    }
  }

  Future<void> _launchDouban(String id) async {
    final launched = await launchUrl(
      Uri.parse('https://movie.douban.com/subject/$id/'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开豆瓣详情')));
    }
  }

  Widget _buildEndIndicator() {
    final state = widget.viewModel.state;
    final count = state.category == '每日放送'
        ? state.calendarItems.length
        : state.animeItems.length;
    final unit = switch (state.category) {
      '每日放送' => '部番剧',
      '番剧' => '部番剧',
      _ => '部动画电影',
    };
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已经到底啦~',
            style: FontUtils.poppins(
              fontSize: 14,
              color: dark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 $count $unit',
            style: FontUtils.poppins(
              fontSize: 12,
              color: dark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey[500],
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  String _label(List<CatalogFilterOption> options, String value) =>
      options.firstWhere((option) => option.value == value).label;
}

const _categories = <CatalogFilterOption>[
  CatalogFilterOption('每日放送', '每日放送'),
  CatalogFilterOption('番剧', '番剧'),
  CatalogFilterOption('剧场版', '剧场版'),
];

const _weekdays = <CatalogFilterOption>[
  CatalogFilterOption('周一', '1'),
  CatalogFilterOption('周二', '2'),
  CatalogFilterOption('周三', '3'),
  CatalogFilterOption('周四', '4'),
  CatalogFilterOption('周五', '5'),
  CatalogFilterOption('周六', '6'),
  CatalogFilterOption('周日', '7'),
];
