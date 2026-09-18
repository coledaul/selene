import 'package:flutter/material.dart';

/// 进度跟随按钮最终前景色，避免品牌色进度叠在同色按钮背景上。
final class AppButtonProgress extends StatelessWidget {
  const AppButtonProgress({
    super.key,
    required this.label,
    this.size = 18,
    this.color,
  });

  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color:
          color ??
          DefaultTextStyle.of(context).style.color ??
          Theme.of(context).colorScheme.onSurface,
      semanticsLabel: label,
    ),
  );
}
