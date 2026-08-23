import 'dart:io';

import 'package:flutter/material.dart';
import 'package:selene/domain/models/catalog.dart';
import 'package:selene/domain/models/live_channel.dart';
import 'package:selene/domain/models/live_source.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/domain/models/video_info.dart';
import 'package:selene/routing/routes.dart';
import 'package:selene/ui/catalog/view_models/anime_view_model.dart';
import 'package:selene/ui/catalog/view_models/catalog_view_model.dart';
import 'package:selene/ui/catalog/widgets/anime_screen.dart';
import 'package:selene/ui/catalog/widgets/catalog_screen.dart';
import 'package:selene/ui/home/view_models/home_view_model.dart';
import 'package:selene/ui/home/widgets/continue_watching_section.dart';
import 'package:selene/ui/home/widgets/favorites_grid.dart';
import 'package:selene/ui/home/widgets/history_grid.dart';
import 'package:selene/ui/home/widgets/home_recommendation_section.dart';
import 'package:selene/ui/live/view_models/live_player_view_model.dart';
import 'package:selene/ui/live/view_models/live_view_model.dart';
import 'package:selene/ui/live/widgets/live_screen.dart';
import 'package:selene/ui/player/view_models/dlna_cast_view_model.dart';
import 'package:selene/ui/search/view_models/search_view_model.dart';
import 'package:selene/ui/search/widgets/search_screen.dart';
import 'package:selene/ui/settings/view_models/settings_view_model.dart';
import 'package:selene/ui/shell/view_models/shell_view_model.dart';
import 'package:selene/ui/shell/widgets/main_layout.dart';
import 'package:selene/ui/core/widgets/custom_refresh_indicator.dart';
import 'package:selene/ui/core/widgets/top_tab_switcher.dart';
import 'package:selene/ui/update/widgets/update_dialog.dart';
import 'package:selene/ui/core/widgets/video_menu_bottom_sheet.dart';
import 'package:selene/utils/font_utils.dart';
import 'package:selene/utils/result.dart';

/// 首页路由作用域：所有工厂仅在 State 初始化时调用一次，并由本页面统一释放。
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.homeViewModelFactory,
    required this.settingsViewModelFactory,
    required this.searchViewModelFactory,
    required this.liveViewModelFactory,
    required this.livePlayerViewModelFactory,
    required this.dlnaCastViewModelFactory,
    required this.catalogViewModelFactory,
    required this.animeViewModelFactory,
    required this.shellViewModelFactory,
  });

  final HomeViewModel Function() homeViewModelFactory;
  final SettingsViewModel Function() settingsViewModelFactory;
  final SearchViewModel Function() searchViewModelFactory;
  final LiveViewModel Function() liveViewModelFactory;
  final LivePlayerViewModel Function(LiveChannel channel, LiveSource source)
  livePlayerViewModelFactory;
  final DlnaCastViewModel Function() dlnaCastViewModelFactory;
  final CatalogViewModel Function(CatalogDefinition definition)
  catalogViewModelFactory;
  final AnimeViewModel Function() animeViewModelFactory;
  final ShellViewModel Function() shellViewModelFactory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late PageController _bottomNavPageController;
  late final HomeViewModel _homeViewModel;
  late final SettingsViewModel _settingsViewModel;
  late final LiveViewModel _liveViewModel;
  late final AnimeViewModel _animeViewModel;
  late final ShellViewModel _shellViewModel;
  late final CatalogViewModel _movieViewModel;
  late final CatalogViewModel _tvViewModel;
  late final CatalogViewModel _showViewModel;

  int get _currentBottomNavIndex => _homeViewModel.state.bottomNavigationIndex;
  String get _selectedTopTab => switch (_homeViewModel.state.topTabIndex) {
    1 => '播放历史',
    2 => '收藏夹',
    _ => '首页',
  };

  @override
  void initState() {
    super.initState();
    // 初始化 PageController，默认显示首页（索引0）
    _pageController = PageController(initialPage: 0);
    // 初始化底栏 PageController
    _bottomNavPageController = PageController(initialPage: 0);
    _homeViewModel = widget.homeViewModelFactory();
    _settingsViewModel = widget.settingsViewModelFactory();
    _liveViewModel = widget.liveViewModelFactory();
    _animeViewModel = widget.animeViewModelFactory();
    _shellViewModel = widget.shellViewModelFactory();
    _movieViewModel = widget.catalogViewModelFactory(CatalogDefinition.movie);
    _tvViewModel = widget.catalogViewModelFactory(CatalogDefinition.tv);
    _showViewModel = widget.catalogViewModelFactory(CatalogDefinition.show);
    _homeViewModel
      ..addListener(_handleViewModelChanged)
      ..initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomNavPageController.dispose();
    _homeViewModel
      ..removeListener(_handleViewModelChanged)
      ..dispose();
    _settingsViewModel.dispose();
    _movieViewModel.dispose();
    _tvViewModel.dispose();
    _showViewModel.dispose();
    _animeViewModel.dispose();
    _liveViewModel.dispose();
    _shellViewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final update = _homeViewModel.state.availableUpdate;
    if (update != null) {
      _homeViewModel.consumeAvailableUpdate();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await UpdateDialog.show(
          context,
          update,
          onDismissVersion: (version) async {
            await _homeViewModel.dismissUpdate.execute(version);
          },
        );
      });
    }
  }

  /// 刷新首页数据
  Future<void> _refreshHomeData() async {
    if (!mounted) return;

    try {
      await _homeViewModel.refreshLibrary.execute();
      await _homeViewModel.refreshContent.execute();

      if (!mounted) return;
      // 强制重建页面
      setState(() {});
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  /// 构建首页内容（带 PageView 支持滑动切换）
  Widget _buildHomeContentWithPageView() {
    return Column(
      children: [
        // 顶部导航栏
        TopTabSwitcher(
          selectedTab: _selectedTopTab,
          onTabChanged: _onTopTabChanged,
        ),
        // PageView 支持左右滑动
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (!mounted) return;

              // 根据页面索引更新选中的标签
              String newTab;
              switch (index) {
                case 0:
                  newTab = '首页';
                  break;
                case 1:
                  newTab = '播放历史';
                  break;
                case 2:
                  newTab = '收藏夹';
                  break;
                default:
                  newTab = '首页';
              }

              // 只在标签真正改变时更新状态
              if (_selectedTopTab != newTab) {
                _homeViewModel.selectTopTab(index);
              }
            },
            children: [
              // 首页内容
              _buildHomeTabContent(),
              // 播放历史内容
              _buildHistoryTabContent(),
              // 收藏夹内容
              _buildFavoritesTabContent(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建首页标签内容
  Widget _buildHomeTabContent() {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: '刷新中...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 继续观看组件
            ContinueWatchingSection(
              viewModel: _homeViewModel,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: _onGlobalMenuAction,
              onViewAll: () {
                // 切换到播放历史标签
                _onTopTabChanged('播放历史');
              },
            ),
            // 热门电影组件
            HomeRecommendationSection(
              viewModel: _homeViewModel,
              kind: HomeRecommendationKind.movie,
              onItemTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerRoute(
                    title: videoInfo.title,
                    stype: 'movie',
                    year: videoInfo.year,
                  ),
                );
              },
              onMoreTap: () => _onBottomNavChanged(1),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerRoute(
                      title: videoInfo.title,
                      stype: 'movie',
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 热门剧集组件
            HomeRecommendationSection(
              viewModel: _homeViewModel,
              kind: HomeRecommendationKind.tv,
              onItemTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerRoute(title: videoInfo.title, year: videoInfo.year),
                );
              },
              onMoreTap: () => _onBottomNavChanged(2),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerRoute(title: videoInfo.title, year: videoInfo.year),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 新番放送组件
            HomeRecommendationSection(
              viewModel: _homeViewModel,
              kind: HomeRecommendationKind.anime,
              onItemTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerRoute(title: videoInfo.title, year: videoInfo.year),
                );
              },
              onMoreTap: () => _onBottomNavChanged(3),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerRoute(title: videoInfo.title, year: videoInfo.year),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 热门综艺组件
            HomeRecommendationSection(
              viewModel: _homeViewModel,
              kind: HomeRecommendationKind.show,
              onItemTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerRoute(title: videoInfo.title, year: videoInfo.year),
                );
              },
              onMoreTap: () => _onBottomNavChanged(4),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerRoute(title: videoInfo.title, year: videoInfo.year),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建播放历史标签内容
  Widget _buildHistoryTabContent() {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: '刷新中...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 4),
            HistoryGrid(
              viewModel: _homeViewModel,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: _onGlobalMenuAction,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建收藏夹标签内容
  Widget _buildFavoritesTabContent() {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: '刷新中...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 4),
            FavoritesGrid(
              viewModel: _homeViewModel,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction:
                  (VideoInfo videoInfo, VideoMenuAction action) {
                    // 将VideoInfo转换为PlayRecord用于统一处理
                    final playRecord = PlayRecord(
                      id: videoInfo.id,
                      source: videoInfo.source,
                      title: videoInfo.title,
                      sourceName: videoInfo.sourceName,
                      year: videoInfo.year,
                      cover: videoInfo.cover,
                      index: videoInfo.index,
                      totalEpisodes: videoInfo.totalEpisodes,
                      playTime: videoInfo.playTime,
                      totalTime: videoInfo.totalTime,
                      saveTime: videoInfo.saveTime,
                      searchTitle: videoInfo.searchTitle,
                    );
                    _onGlobalMenuAction(playRecord, action);
                  },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      viewModel: _shellViewModel,
      settingsViewModel: _settingsViewModel,
      content: _buildBottomNavPageView(),
      currentBottomNavIndex: _currentBottomNavIndex,
      onBottomNavChanged: _onBottomNavChanged,
      selectedTopTab: _selectedTopTab,
      onTopTabChanged: _onTopTabChanged,
      onHomeTap: _onHomeTap,
      onSearchTap: _onSearchTap,
    );
  }

  /// 构建底栏 PageView，支持左右滑动切换
  Widget _buildBottomNavPageView() {
    return PageView(
      controller: _bottomNavPageController,
      onPageChanged: (index) {
        if (!mounted) return;
        if (_currentBottomNavIndex != index) {
          _homeViewModel.selectBottomNavigation(index);
        }
      },
      children: [
        _buildHomeContentWithPageView(),
        CatalogScreen(viewModel: _movieViewModel),
        CatalogScreen(viewModel: _tvViewModel),
        AnimeScreen(viewModel: _animeViewModel),
        CatalogScreen(viewModel: _showViewModel),
        LiveScreen(
          viewModel: _liveViewModel,
          playerViewModelFactory: widget.livePlayerViewModelFactory,
          dlnaCastViewModelFactory: widget.dlnaCastViewModelFactory,
        ),
      ],
    );
  }

  /// 处理底部导航栏切换
  void _onBottomNavChanged(int index) {
    if (!mounted) return;

    // 防止重复点击同一个标签
    if (_currentBottomNavIndex == index) {
      return;
    }

    _homeViewModel.selectBottomNavigation(index);

    // 使用动画切换到对应页面
    if (_bottomNavPageController.hasClients) {
      _bottomNavPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 处理顶部标签切换
  void _onTopTabChanged(String tab) {
    if (!mounted) return;

    // 防止重复点击同一个标签
    if (_selectedTopTab == tab) {
      return;
    }

    // 同步 PageView 的页面切换
    int pageIndex;
    switch (tab) {
      case '首页':
        pageIndex = 0;
        break;
      case '播放历史':
        pageIndex = 1;
        break;
      case '收藏夹':
        pageIndex = 2;
        break;
      default:
        pageIndex = 0;
    }
    _homeViewModel.selectTopTab(pageIndex);

    // 使用动画切换到对应页面
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 处理点击搜索按钮
  void _onSearchTap() {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            viewModelFactory: widget.searchViewModelFactory,
            shellViewModelFactory: widget.shellViewModelFactory,
            settingsViewModel: _settingsViewModel,
          ),
        ),
      ).then((_) {
        // 从搜索页面返回时刷新数据
        if (mounted) {
          _refreshOnResume();
        }
      });
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(
            viewModelFactory: widget.searchViewModelFactory,
            shellViewModelFactory: widget.shellViewModelFactory,
            settingsViewModel: _settingsViewModel,
          ),
          transitionDuration: Duration.zero, // 无打开动画
          reverseTransitionDuration: Duration.zero, // 无关闭动画
        ),
      ).then((_) {
        // 从搜索页面返回时刷新数据
        if (mounted) {
          _refreshOnResume();
        }
      });
    }
  }

  /// 处理点击 Selene 标题跳转到首页
  void _onHomeTap() {
    if (!mounted) return;

    _homeViewModel.selectHome();

    // 使用动画切换到首页
    if (_bottomNavPageController.hasClients) {
      _bottomNavPageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // 同时切换顶部标签到首页
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 处理视频卡片点击
  void _onVideoTap(PlayRecord playRecord) {
    _navigateToPlayer(
      PlayerRoute(
        source: playRecord.source,
        id: playRecord.id,
        title: playRecord.title,
        year: playRecord.year,
      ),
    );
  }

  /// 处理来自VideoInfo的全局菜单操作
  void _onGlobalMenuActionFromVideoInfo(
    VideoInfo videoInfo,
    VideoMenuAction action,
  ) {
    // 将VideoInfo转换为PlayRecord用于统一处理
    final playRecord = PlayRecord(
      id: videoInfo.id,
      source: videoInfo.source,
      title: videoInfo.title,
      sourceName: videoInfo.sourceName,
      year: videoInfo.year,
      cover: videoInfo.cover,
      index: videoInfo.index,
      totalEpisodes: videoInfo.totalEpisodes,
      playTime: videoInfo.playTime,
      totalTime: videoInfo.totalTime,
      saveTime: videoInfo.saveTime,
      searchTitle: videoInfo.searchTitle,
    );
    _onGlobalMenuAction(playRecord, action);
  }

  /// 处理视频菜单操作
  void _onGlobalMenuAction(PlayRecord playRecord, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        _navigateToPlayer(
          PlayerRoute(
            source: playRecord.source,
            id: playRecord.id,
            title: playRecord.title,
            year: playRecord.year,
          ),
        );
        break;
      case VideoMenuAction.favorite:
        // 收藏
        _handleFavorite(playRecord);
        break;
      case VideoMenuAction.unfavorite:
        // 取消收藏
        _handleUnfavorite(playRecord);
        break;
      case VideoMenuAction.deleteRecord:
        // 删除记录
        _deletePlayRecord(playRecord);
        break;
      case VideoMenuAction.doubanDetail:
        // 豆瓣详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在打开豆瓣详情: ${playRecord.title}',
              style: FontUtils.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3498DB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
      case VideoMenuAction.bangumiDetail:
        // Bangumi详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在打开 Bangumi 详情: ${playRecord.title}',
              style: FontUtils.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3498DB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
    }
  }

  /// 删除播放记录
  Future<void> _deletePlayRecord(PlayRecord playRecord) async {
    final result = await _homeViewModel.deleteRecord.execute(playRecord);
    if (!mounted) {
      return;
    }
    if (result case FailureResult<void>(:final failure)) {
      _showFailure(failure.message);
      await _refreshPlayRecordsCache();
    }
  }

  /// 异步刷新播放记录缓存
  Future<void> _refreshPlayRecordsCache() async {
    await _homeViewModel.refreshLibrary.execute();
  }

  /// 跳转到播放页的通用方法
  Future<void> _navigateToPlayer(PlayerRoute route) async {
    await route.push<void>(context);

    if (!mounted) return;
    _refreshOnResume();
  }

  /// 从播放页返回时刷新播放记录
  Future<void> _refreshOnResume() async {
    if (!mounted) return;
    await _homeViewModel.refreshLibrary.execute();
  }

  /// 处理收藏
  Future<void> _handleFavorite(PlayRecord playRecord) async {
    final result = await _homeViewModel.addFavorite.execute(playRecord);
    if (!mounted) {
      return;
    }
    if (result case FailureResult<void>(:final failure)) {
      _showFailure(failure.message);
      await _refreshFavorites();
    } else {
      setState(() {});
    }
  }

  /// 处理取消收藏
  Future<void> _handleUnfavorite(PlayRecord playRecord) async {
    final result = await _homeViewModel.removeFavorite.execute(playRecord);
    if (!mounted) {
      return;
    }
    if (result case FailureResult<void>(:final failure)) {
      _showFailure(failure.message);
      await _refreshFavorites();
    }
  }

  /// 异步刷新收藏夹数据
  Future<void> _refreshFavorites() async {
    await _homeViewModel.refreshLibrary.execute();
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FontUtils.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
