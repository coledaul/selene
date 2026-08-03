import 'package:flutter/material.dart';

/// 保留当前媒体的播放完成操作层。
final class PlaybackCompletedOverlay extends StatelessWidget {
  const PlaybackCompletedOverlay({
    super.key,
    required this.isLastEpisode,
    required this.onReplay,
    this.onNextEpisode,
    this.onBackPressed,
  });

  final bool isLastEpisode;
  final Future<void> Function() onReplay;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final showNext = !isLastEpisode && onNextEpisode != null;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: Semantics(
          container: true,
          label: '播放完成',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text(
                '播放完成',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay),
                    label: const Text('重新播放'),
                  ),
                  if (showNext)
                    OutlinedButton.icon(
                      onPressed: onNextEpisode,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('下一集'),
                    ),
                  if (isLastEpisode && onBackPressed != null)
                    TextButton(
                      onPressed: onBackPressed,
                      child: const Text('返回'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
