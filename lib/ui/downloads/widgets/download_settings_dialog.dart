import 'package:flutter/material.dart';

import 'package:selene/domain/models/video_download_settings.dart';

Future<int?> showDownloadSettingsDialog({
  required BuildContext context,
  required int currentValue,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => DownloadSettingsDialog(currentValue: currentValue),
  );
}

class DownloadSettingsDialog extends StatelessWidget {
  const DownloadSettingsDialog({required this.currentValue, super.key});

  final int currentValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('下载设置'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同时下载任务数', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '多个任务同时下载会共享网络带宽',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (
              var value = VideoDownloadSettings.minConcurrentDownloads;
              value <= VideoDownloadSettings.maxConcurrentDownloadsLimit;
              value++
            )
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  value == currentValue
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: value == currentValue
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  value == VideoDownloadSettings.defaultMaxConcurrentDownloads
                      ? '$value 个（默认）'
                      : '$value 个',
                ),
                selected: value == currentValue,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
