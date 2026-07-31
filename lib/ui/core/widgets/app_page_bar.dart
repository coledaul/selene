import 'package:flutter/material.dart';

import '../../../utils/device_utils.dart';
import '../../../utils/font_utils.dart';
import 'app_back_button.dart';

/// 独立业务页面共用的标题栏，统一标题、返回和操作区的视觉规则。
final class AppPageBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageBar({
    super.key,
    required this.title,
    this.titleIcon,
    this.titleIconColor,
    this.actions = const <Widget>[],
    this.leading,
    this.onBackPressed,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.backgroundColor,
    this.foregroundColor,
    this.toolbarHeight = 60,
  });

  final String title;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final List<Widget> actions;
  final Widget? leading;
  final VoidCallback? onBackPressed;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        theme.colorScheme.onSurface;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final impliedLeading =
        automaticallyImplyLeading && (onBackPressed != null || canPop)
        ? AppBackButton(onPressed: onBackPressed, foregroundColor: foreground)
        : null;
    final effectiveLeading = leading ?? impliedLeading;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: effectiveLeading,
      leadingWidth: effectiveLeading == null ? null : 56,
      titleSpacing: effectiveLeading == null ? 20 : 0,
      toolbarHeight: toolbarHeight,
      centerTitle: centerTitle ?? !DeviceUtils.isPC(),
      backgroundColor: backgroundColor,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleIcon case final icon?) ...[
            Icon(icon, size: 20, color: titleIconColor ?? foreground),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FontUtils.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
      actions: actions.isEmpty
          ? null
          : <Widget>[...actions, const SizedBox(width: 8)],
    );
  }
}
