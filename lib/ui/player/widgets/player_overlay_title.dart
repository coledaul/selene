import 'package:flutter/material.dart';

/// 播放器控制层共用的单行标题，随控制层一起显示和隐藏。
final class PlayerOverlayTitle extends StatelessWidget {
  const PlayerOverlayTitle({
    super.key,
    required this.title,
    required this.visible,
    required this.top,
    required this.left,
    required this.right,
  });

  final String? title;
  final bool visible;
  final double top;
  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    final value = title?.trim();
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
