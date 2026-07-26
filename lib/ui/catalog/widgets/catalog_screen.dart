import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/catalog.dart';
import '../../../domain/models/video_info.dart';
import '../../../routing/routes.dart';
import '../../../utils/device_utils.dart';
import '../../../utils/font_utils.dart';
import 'capsule_tab_switcher.dart';
import 'douban_movies_grid.dart';
import '../../core/layout/poster_grid_metrics.dart';
import '../../core/utils/scroll_prefetch_policy.dart';
import '../../core/widgets/custom_refresh_indicator.dart';
import '../../core/widgets/filter_options_selector.dart';
import '../../core/widgets/filter_pill_hover.dart';
import '../../core/widgets/pulsing_dots_indicator.dart';
import '../../core/widgets/video_menu_bottom_sheet.dart';
import '../view_models/catalog_view_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.viewModel});

  /// 由首页作用域持有生命周期，本页面只订阅状态。
  final CatalogViewModel viewModel;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastLoadedPage = 0;

  CatalogDefinition get _definition => widget.viewModel.definition;

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
    if (state.items.isEmpty) return;

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
      refreshText: '刷新${_definition.title}数据...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilters(),
            const SizedBox(height: 16),
            DoubanMoviesGrid(
              movies: state.items,
              isLoading: state.loading && state.items.isEmpty,
              errorMessage: state.error,
              onVideoTap: _openPlayer,
              onGlobalMenuAction: _handleMenuAction,
              contentType: _definition.type == CatalogType.movie
                  ? 'movie'
                  : 'tv',
            ),
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: PulsingDotsIndicator(),
              )
            else if (!state.hasMore && state.items.isNotEmpty && !state.loading)
              _buildEndIndicator(state.items.length)
            else
              const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _definition.title,
            style: FontUtils.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            child: Text(
              '来自豆瓣的精选内容',
              style: FontUtils.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          _buildOptionRow(
            '分类',
            _definition.primaryOptions,
            state.category,
            widget.viewModel.selectCategory,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 66,
            child: state.category == '全部'
                ? _buildAdvancedFilters()
                : _buildSecondaryFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    final state = widget.viewModel.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '筛选',
          style: FontUtils.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(
                  '类型',
                  _definition.typeOptions,
                  state.type,
                  widget.viewModel.selectType,
                ),
                _buildFilterPill(
                  '地区',
                  _definition.regionOptions,
                  state.region,
                  widget.viewModel.selectRegion,
                ),
                _buildFilterPill(
                  '年代',
                  _definition.yearOptions,
                  state.year,
                  widget.viewModel.selectYear,
                ),
                if (_definition.supportsPlatform)
                  _buildFilterPill(
                    '平台',
                    _definition.platformOptions,
                    state.platform,
                    widget.viewModel.selectPlatform,
                  ),
                _buildFilterPill(
                  '排序',
                  _definition.sortOptions,
                  state.sort,
                  widget.viewModel.selectSort,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryFilters() {
    final state = widget.viewModel.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _definition.type == CatalogType.movie ? '地区' : '类型',
          style: FontUtils.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
            tabs: _definition.secondaryOptions
                .map((option) => option.label)
                .toList(growable: false),
            selectedTab: _definition.labelFor(
              _definition.secondaryOptions,
              state.secondary,
            ),
            onTabChanged: (label) {
              final value = _definition.secondaryOptions
                  .firstWhere((option) => option.label == label)
                  .value;
              widget.viewModel.selectSecondary(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionRow(
    String title,
    List<CatalogFilterOption> options,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FontUtils.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
            tabs: options.map((option) => option.label).toList(growable: false),
            selectedTab: _definition.labelFor(options, selectedValue),
            onTabChanged: (label) {
              onSelected(
                options.firstWhere((option) => option.label == label).value,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(
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
            .toList(growable: false),
        selectedValue: selectedValue,
        onSelected: onSelected,
      ),
    );
  }

  void _openPlayer(VideoInfo video) {
    PlayerRoute(
      title: video.title,
      year: video.year,
      stype: _definition.type == CatalogType.movie ? 'movie' : null,
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
    final uri = Uri.parse('https://movie.douban.com/subject/$id/');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开豆瓣详情')));
    }
  }

  Widget _buildEndIndicator(int count) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 2,
            color: dark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '已经到底啦~',
            style: FontUtils.poppins(
              fontSize: 14,
              color: dark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 $count ${_definition.countSuffix}',
            style: FontUtils.poppins(
              fontSize: 12,
              color: dark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
