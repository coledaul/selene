import 'package:flutter/material.dart';

import '../themes/app_tokens.dart';
import 'app_button_progress.dart';

/// 普通业务操作统一图标尺寸和点击范围，加载时保持布局稳定。
final class AppIconActionButton extends StatelessWidget {
  const AppIconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.foregroundColor,
    this.loading = false,
    this.isSelected,
    this.selectedIcon,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final bool loading;
  final bool? isSelected;
  final IconData? selectedIcon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : onPressed,
      isSelected: isSelected,
      selectedIcon: selectedIcon == null
          ? null
          : Icon(selectedIcon, size: AppMetrics.actionIcon),
      style: IconButton.styleFrom(
        foregroundColor: foregroundColor,
        minimumSize: const Size.square(AppMetrics.touchTarget),
        maximumSize: const Size.square(AppMetrics.touchTarget),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.iconButtonRadius),
        ),
      ),
      icon: loading
          ? AppButtonProgress(
              label: tooltip,
              size: 20,
              color:
                  foregroundColor ??
                  (isSelected == true
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : Icon(icon, size: AppMetrics.actionIcon),
    );
  }
}
