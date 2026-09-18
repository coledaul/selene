import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_icon_action_button.dart';

/// 详情标题旁的操作；保留收藏的红色实心状态，与下载入口使用相同点击范围。
final class PlayerDetailActions extends StatelessWidget {
  const PlayerDetailActions({
    super.key,
    required this.isFavorite,
    required this.onDownload,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final VoidCallback onDownload;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconActionButton(
          icon: LucideIcons.download,
          tooltip: '下载视频',
          onPressed: onDownload,
        ),
        const SizedBox(width: 4),
        AppIconActionButton(
          icon: LucideIcons.heart,
          selectedIcon: Icons.favorite_rounded,
          tooltip: isFavorite ? '取消收藏' : '收藏',
          isSelected: isFavorite,
          foregroundColor: isFavorite ? const Color(0xFFe74c3c) : null,
          onPressed: onToggleFavorite,
        ),
      ],
    );
  }
}
