import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/search_result.dart';
import '../../../services/media_url_resolver.dart';
import '../application/video_download_manager.dart';
import '../domain/video_download_task.dart';

Future<int?> showDownloadSelectionSheet({
  required BuildContext context,
  required SearchResult detail,
  required int currentEpisodeIndex,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _DownloadSelectionSheet(
      detail: detail,
      currentEpisodeIndex: currentEpisodeIndex,
    ),
  );
}

class _DownloadSelectionSheet extends StatefulWidget {
  const _DownloadSelectionSheet({
    required this.detail,
    required this.currentEpisodeIndex,
  });

  final SearchResult detail;
  final int currentEpisodeIndex;

  @override
  State<_DownloadSelectionSheet> createState() =>
      _DownloadSelectionSheetState();
}

class _DownloadSelectionSheetState extends State<_DownloadSelectionSheet> {
  late final Set<int> _selectedIndexes = <int>{widget.currentEpisodeIndex};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodes = widget.detail.episodes;
    return FractionallySizedBox(
      heightFactor: episodes.length > 6 ? 0.78 : null,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize:
              episodes.length > 6 ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '下载视频',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.detail.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _selectedIndexes
                              ..clear()
                              ..add(widget.currentEpisodeIndex);
                          }),
                  child: const Text('仅当前集'),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _selectedIndexes
                              ..clear()
                              ..addAll(
                                List<int>.generate(episodes.length, (i) => i),
                              );
                          }),
                  child: const Text('全选'),
                ),
                const Spacer(),
                Text(
                  '已选 ${_selectedIndexes.length} 集',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const Divider(height: 1),
            if (episodes.length > 6)
              Expanded(child: _buildEpisodeList())
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: _buildEpisodeList(),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _selectedIndexes.isEmpty || _submitting
                    ? null
                    : _enqueueSelected,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _submitting ? '正在创建任务...' : '下载 ${_selectedIndexes.length} 集',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.detail.episodes.length,
      itemBuilder: (context, index) {
        final selected = _selectedIndexes.contains(index);
        return CheckboxListTile(
          value: selected,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(_episodeTitle(index)),
          subtitle:
              index == widget.currentEpisodeIndex ? const Text('当前播放') : null,
          onChanged: _submitting
              ? null
              : (value) => setState(() {
                    if (value ?? false) {
                      _selectedIndexes.add(index);
                    } else {
                      _selectedIndexes.remove(index);
                    }
                  }),
        );
      },
    );
  }

  Future<void> _enqueueSelected() async {
    setState(() => _submitting = true);
    try {
      final indexes = _selectedIndexes.toList()..sort();
      final requests = <VideoDownloadRequest>[];
      for (final index in indexes) {
        final resolvedUrl = await MediaUrlResolver.resolve(
          widget.detail.episodes[index],
        );
        requests.add(
          VideoDownloadRequest(
            source: widget.detail.source,
            contentId: widget.detail.id,
            sourceName: widget.detail.sourceName,
            title: widget.detail.title,
            coverUrl: widget.detail.poster,
            episodeIndex: index,
            episodeTitle: _episodeTitle(index),
            totalEpisodes: widget.detail.episodes.length,
            mediaUrl: resolvedUrl,
          ),
        );
      }
      if (!mounted) return;
      await context.read<VideoDownloadManager>().enqueueAll(requests);
      if (!mounted) return;
      Navigator.of(context).pop(requests.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建下载任务失败，请稍后重试')),
      );
    }
  }

  String _episodeTitle(int index) {
    final titles = widget.detail.episodesTitles;
    if (index < titles.length && titles[index].trim().isNotEmpty) {
      return titles[index].trim();
    }
    return widget.detail.episodes.length == 1 ? '正片' : '第 ${index + 1} 集';
  }
}
