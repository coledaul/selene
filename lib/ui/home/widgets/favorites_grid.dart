import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:selene/domain/models/favorite_item.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/domain/models/video_info.dart';
import 'package:selene/ui/core/widgets/shimmer_effect.dart';
import 'package:selene/ui/core/widgets/video_card.dart';
import 'package:selene/ui/core/widgets/video_menu_bottom_sheet.dart';
import 'package:selene/ui/home/view_models/home_view_model.dart';
import 'package:selene/utils/device_utils.dart';
import 'package:selene/utils/font_utils.dart';

class FavoritesGrid extends StatefulWidget {
  final HomeViewModel viewModel;
  final Function(PlayRecord) onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;

  const FavoritesGrid({
    super.key,
    required this.viewModel,
    required this.onVideoTap,
    this.onGlobalMenuAction,
  });

  @override
  State<FavoritesGrid> createState() => _FavoritesGridState();
}

class _FavoritesGridState extends State<FavoritesGrid>
    with TickerProviderStateMixin {
  List<FavoriteItem> _favorites = [];
  List<PlayRecord> _playRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    widget.viewModel.addListener(_syncViewModel);
    _syncViewModel();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncViewModel);
    super.dispose();
  }

  void _syncViewModel() {
    if (!mounted) return;
    final state = widget.viewModel.state;
    setState(() {
      _favorites = state.favorites;
      _playRecords = state.playRecords;
      _isLoading = state.favoritesLoading;
      _errorMessage = state.favoritesError;
    });
  }

  Future<void> _loadData() async {
    await widget.viewModel.refreshLibrary.execute();
  }

  Future<void> _loadFavorites() async {
    await widget.viewModel.refreshFavorites.execute();
  }

  PlayRecord _favoriteToPlayRecord(FavoriteItem favorite) {
    // 查找匹配的播放记录
    try {
      final matchingPlayRecord = _playRecords.firstWhere(
        (record) =>
            record.source == favorite.source && record.id == favorite.id,
      );
      // 如果有匹配的播放记录，使用播放记录的数据
      return matchingPlayRecord;
    } catch (e) {
      // 如果没有匹配的播放记录，使用收藏夹的默认数据
      return PlayRecord(
        id: favorite.id,
        source: favorite.source,
        title: favorite.title,
        cover: favorite.cover,
        year: favorite.year,
        sourceName: favorite.sourceName,
        totalEpisodes: favorite.totalEpisodes,
        index: 0, // 0表示没有播放记录
        playTime: 0, // 未播放
        totalTime: 0, // 未知总时长
        saveTime: favorite.saveTime,
        searchTitle: favorite.title, // 使用标题作为搜索标题
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return _buildFavoritesGrid();
  }

  Widget _buildLoadingState() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF27ae60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 平板模式根据宽度动态展示6～9列，手机模式3列
          final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
          final isTablet = DeviceUtils.isTablet(context);

          // 计算每列的宽度
          final double screenWidth = constraints.maxWidth;
          const double padding = 16.0; // 左右padding
          const double spacing = 12.0; // 列间距
          final double availableWidth =
              screenWidth -
              (padding * 2) -
              (spacing * (crossAxisCount - 1)); // 减去padding和间距
          // 确保最小宽度，防止负宽度约束
          const double minItemWidth = 80.0; // 最小项目宽度
          final double calculatedItemWidth = availableWidth / crossAxisCount;
          final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
          final double itemHeight = itemWidth * 2.0; // 增加高度比例，确保有足够空间避免溢出

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
              crossAxisSpacing: spacing, // 列间距
              mainAxisSpacing: isTablet ? 0 : 16, // 行间距
            ),
            itemCount: isTablet ? crossAxisCount * 2 : 6, // 平板显示2行，手机显示6个骨架卡片
            itemBuilder: (context, index) {
              return _buildSkeletonCard(itemWidth);
            },
          );
        },
      ),
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.4; // 保持与VideoCard相同的比例

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 封面骨架
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 4),
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 2),
        // 源名称骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.6,
            height: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: const Color(0xFFbdc3c7)),
          const SizedBox(height: 24),
          Text(
            '加载失败',
            style: FontUtils.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? '未知错误',
            style: FontUtils.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFavorites,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '重试',
              style: FontUtils.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 120.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 80,
              color: Color(0xFFbdc3c7),
            ),
            const SizedBox(height: 24),
            Text(
              '暂无收藏内容',
              style: FontUtils.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7f8c8d),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '您收藏的视频将显示在这里',
              style: FontUtils.poppins(
                fontSize: 14,
                color: const Color(0xFF95a5a6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: const Color(0xFF27ae60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 平板模式根据宽度动态展示6～9列，手机模式3列
          final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
          final isTablet = DeviceUtils.isTablet(context);

          // 计算每列的宽度
          final double screenWidth = constraints.maxWidth;
          const double padding = 16.0; // 左右padding
          const double spacing = 12.0; // 列间距
          final double availableWidth =
              screenWidth -
              (padding * 2) -
              (spacing * (crossAxisCount - 1)); // 减去padding和间距
          // 确保最小宽度，防止负宽度约束
          const double minItemWidth = 80.0; // 最小项目宽度
          final double calculatedItemWidth = availableWidth / crossAxisCount;
          final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
          final double itemHeight = itemWidth * 2.0; // 增加高度比例，确保有足够空间避免溢出

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
              crossAxisSpacing: spacing, // 列间距
              mainAxisSpacing: isTablet ? 0 : 16, // 行间距
            ),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final favorite = _favorites[index];
              final playRecord = _favoriteToPlayRecord(favorite);

              return VideoCard(
                videoInfo: VideoInfo.fromPlayRecord(playRecord),
                onTap: () => widget.onVideoTap(playRecord),
                from: 'favorite', // 统一设置为收藏场景
                cardWidth: itemWidth, // 传递计算出的宽度
                onGlobalMenuAction: widget.onGlobalMenuAction != null
                    ? (action) => widget.onGlobalMenuAction!(
                        VideoInfo.fromPlayRecord(playRecord),
                        action,
                      )
                    : null,
                isFavorited: true, // 收藏页面默认已收藏
              );
            },
          );
        },
      ),
    );
  }
}
