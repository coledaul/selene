import 'dart:async';

import 'package:flutter/material.dart';

import '../video_playback_session.dart';

/// 统一呈现播放器的阻断错误、可恢复错误与非致命降级。
class PlaybackProblemPresenter extends StatelessWidget {
  const PlaybackProblemPresenter({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onDismiss,
  });

  final VideoPlaybackState state;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (failure != null && !state.ready) {
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.72),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    failure.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (state.failureRetryable) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => unawaited(onRetry()),
                    child: const Text('重试'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final problem = failure ?? state.warning;
    if (problem == null) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      problem.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (failure != null && state.failureRetryable)
                    TextButton(
                      onPressed: () => unawaited(onRetry()),
                      child: const Text('重试'),
                    ),
                  IconButton(
                    onPressed: onDismiss,
                    tooltip: '关闭提示',
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
