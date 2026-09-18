import 'package:flutter/material.dart';

/// 固定品牌色；随明暗变化的语义颜色由 AppTheme 映射到 ColorScheme。
abstract final class AppBrand {
  static const primary = Color(0xFF27AE60);
  static const hover = Color(0xFF52C77A);
  static const bright = Color(0xFF2ECC71);
}

/// 常规控件尺寸，不约束播放器控制层或业务布局。
abstract final class AppMetrics {
  static const buttonRadius = 8.0;
  static const iconButtonRadius = 12.0;
  static const dialogRadius = 16.0;
  static const touchTarget = 48.0;
  static const actionIcon = 22.0;
}
