import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 普通页面和加载层共用的返回按钮。
///
/// 播放器控制层有全屏、锁定和控件显隐语义，不应直接替换为此组件。
final class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.foregroundColor,
    this.hoverColor,
    this.iconSize = 22,
    this.buttonSize = 40,
    this.tooltip = '返回',
  });

  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? hoverColor;
  final double iconSize;
  final double buttonSize;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final foreground =
        foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return Material(
      type: MaterialType.transparency,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        icon: Icon(LucideIcons.arrowLeft, size: iconSize, weight: 1.5),
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          hoverColor: hoverColor ?? foreground.withValues(alpha: 0.10),
          highlightColor: foreground.withValues(alpha: 0.14),
          minimumSize: Size.square(buttonSize),
          maximumSize: Size.square(buttonSize),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
