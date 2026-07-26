import 'package:flutter/material.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/domain/models/video_info.dart';
import 'package:selene/ui/core/widgets/shimmer_effect.dart';
import 'package:selene/ui/core/widgets/video_card.dart';
import 'package:selene/ui/core/widgets/video_menu_bottom_sheet.dart';
import 'package:selene/ui/core/layout/poster_grid_metrics.dart';
import 'package:selene/utils/device_utils.dart';
import 'package:selene/utils/font_utils.dart';

class DoubanMoviesGrid extends StatelessWidget {
  final List<DoubanMovie>? movies;
  final bool isLoading;
  final String? errorMessage;
  final Function(VideoInfo) onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final String contentType; // 'movie' 或 'tv'

  const DoubanMoviesGrid({
    super.key,
    this.movies,
    this.isLoading = false,
    this.errorMessage,
    required this.onVideoTap,
    this.onGlobalMenuAction,
    this.contentType = 'movie', // 默认为电影
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && (movies == null || movies!.isEmpty)) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (movies == null || movies!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMoviesGrid();
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final isTablet = DeviceUtils.isTablet(context);

        final metrics = PosterGridMetrics.calculate(
          availableWidth: constraints.maxWidth,
          crossAxisCount: crossAxisCount,
          isTablet: isTablet,
        );

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: metrics.itemWidth / metrics.itemHeight,
            crossAxisSpacing: PosterGridMetrics.crossAxisSpacing,
            mainAxisSpacing: metrics.mainAxisSpacing,
          ),
          itemCount: isTablet ? crossAxisCount * 2 : 6, // 平板显示2行，手机显示6个骨架卡片
          itemBuilder: (context, index) {
            return _buildSkeletonCard(metrics.itemWidth);
          },
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.5;

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
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Color(0xFFbdc3c7)),
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
            errorMessage ?? '未知错误',
            style: FontUtils.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isMovie = contentType == 'movie';
    final String contentName = isMovie ? '电影' : '剧集';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMovie ? Icons.movie_filter_outlined : Icons.tv_outlined,
            size: 80,
            color: const Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无$contentName',
            style: FontUtils.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '当前分类下没有$contentName',
            style: FontUtils.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final isTablet = DeviceUtils.isTablet(context);

        final metrics = PosterGridMetrics.calculate(
          availableWidth: constraints.maxWidth,
          crossAxisCount: crossAxisCount,
          isTablet: isTablet,
        );

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: metrics.itemWidth / metrics.itemHeight,
            crossAxisSpacing: PosterGridMetrics.crossAxisSpacing,
            mainAxisSpacing: metrics.mainAxisSpacing,
          ),
          itemCount: movies!.length,
          itemBuilder: (context, index) {
            final movie = movies![index];
            final videoInfo = movie.toVideoInfo();

            return VideoCard(
              videoInfo: videoInfo,
              onTap: () => onVideoTap(videoInfo),
              from: 'douban',
              cardWidth: metrics.itemWidth,
              onGlobalMenuAction: onGlobalMenuAction != null
                  ? (action) => onGlobalMenuAction!(videoInfo, action)
                  : null,
              isFavorited: false,
            );
          },
        );
      },
    );
  }
}
