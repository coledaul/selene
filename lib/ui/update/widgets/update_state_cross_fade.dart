import 'package:flutter/material.dart';

/// 更新操作的两态内容共用占位，只淡化，不缩放、滑动或延迟业务状态。
/// 两层始终参与布局，大字体换行和快速反向切换也不改变周围控件位置。
final class UpdateStateCrossFade extends StatelessWidget {
  const UpdateStateCrossFade({
    super.key,
    required this.showSecond,
    required this.firstChild,
    required this.secondChild,
    this.alignment = AlignmentDirectional.centerStart,
  });

  static const duration = Duration(milliseconds: 120);

  final bool showSecond;
  final Widget firstChild;
  final Widget secondChild;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget layer(Widget child, bool visible) => IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: reduceMotion
            ? Opacity(opacity: visible ? 1 : 0, child: child)
            : AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: duration,
                alwaysIncludeSemantics: true,
                child: child,
              ),
      ),
    );
    return Stack(
      alignment: alignment,
      children: [
        layer(firstChild, !showSecond),
        layer(secondChild, showSecond),
      ],
    );
  }
}
