import 'package:flutter/material.dart';

import '../../../domain/models/play_record.dart';
import '../../../domain/models/video_info.dart';
import '../../home/view_models/home_view_model.dart';
import '../../core/widgets/recommendation_section.dart';
import '../../core/widgets/video_menu_bottom_sheet.dart';

class HomeRecommendationSection extends StatelessWidget {
  const HomeRecommendationSection({
    super.key,
    required this.viewModel,
    required this.kind,
    required this.onItemTap,
    required this.onMoreTap,
    this.onGlobalMenuAction,
  });

  final HomeViewModel viewModel;
  final HomeRecommendationKind kind;
  final ValueChanged<PlayRecord> onItemTap;
  final VoidCallback onMoreTap;
  final void Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final state = viewModel.state;
        final videos = switch (kind) {
          HomeRecommendationKind.movie => state.hotMovies,
          HomeRecommendationKind.tv => state.hotTvShows,
          HomeRecommendationKind.anime => state.todayAnime,
          HomeRecommendationKind.show => state.hotShows,
        };
        final sectionKey = kind.name;
        final hasContent = videos.isNotEmpty;
        final isLoading = state.loadingSections.contains(sectionKey);
        final hasError = state.failedSections.contains(sectionKey);
        final refreshStatus = switch ((hasContent, isLoading, hasError)) {
          (true, true, _) => RecommendationRefreshStatus.refreshing,
          (true, false, true) => RecommendationRefreshStatus.failed,
          _ => RecommendationRefreshStatus.idle,
        };
        return RecommendationSection(
          title: switch (kind) {
            HomeRecommendationKind.movie => '热门电影',
            HomeRecommendationKind.tv => '热门剧集',
            HomeRecommendationKind.anime => '新番放送',
            HomeRecommendationKind.show => '热门综艺',
          },
          moreText: '查看更多 >',
          onMoreTap: onMoreTap,
          videoInfos: videos,
          onItemTap: (video) => onItemTap(_toPlayRecord(video)),
          onGlobalMenuAction: onGlobalMenuAction,
          isLoading: isLoading && !hasContent,
          hasError: hasError && !hasContent,
          refreshStatus: refreshStatus,
          onRetry: () => viewModel.refreshRecommendation.execute(kind),
          cardCount: 2.75,
        );
      },
    );
  }

  PlayRecord _toPlayRecord(VideoInfo video) {
    return PlayRecord(
      id: video.id,
      source: video.source,
      title: video.title,
      sourceName: video.sourceName,
      year: video.year,
      cover: video.cover,
      index: video.index,
      totalEpisodes: video.totalEpisodes,
      playTime: video.playTime,
      totalTime: video.totalTime,
      saveTime: video.saveTime,
      searchTitle: video.searchTitle,
    );
  }
}
