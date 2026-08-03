import 'package:flutter/material.dart';

import '../video_playback_session.dart';
import 'playback_completed_overlay.dart';
import 'playback_problem_presenter.dart';

/// 统一播放完成态与问题提示的显示优先级。
final class PlaybackStatusOverlay extends StatelessWidget {
  const PlaybackStatusOverlay({
    super.key,
    required this.state,
    required this.live,
    required this.isLastEpisode,
    required this.onRetry,
    required this.onDismiss,
    required this.onReplay,
    this.onNextEpisode,
    this.onBackPressed,
  });

  final VideoPlaybackState state;
  final bool live;
  final bool isLastEpisode;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;
  final Future<void> Function() onReplay;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final showCompleted = state.completed && !live && state.failure == null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showCompleted)
          PlaybackCompletedOverlay(
            isLastEpisode: isLastEpisode,
            onReplay: onReplay,
            onNextEpisode: onNextEpisode,
            onBackPressed: onBackPressed,
          ),
        PlaybackProblemPresenter(
          state: state,
          onRetry: onRetry,
          onDismiss: onDismiss,
        ),
      ],
    );
  }
}
