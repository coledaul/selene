import 'dart:math' as math;

/// 根据当前视口与内容行高决定是否预取下一页。
abstract final class ScrollPrefetchPolicy {
  static const double _targetViewportFraction = 0.5;

  /// 预取距离至少覆盖一行，通常为半屏，且不会超过一屏。
  static double calculateThreshold({
    required double viewportExtent,
    required double rowExtent,
  }) {
    if (!viewportExtent.isFinite || viewportExtent <= 0) return 0;
    if (!rowExtent.isFinite || rowExtent <= 0) return 0;

    final target = viewportExtent * _targetViewportFraction;
    return math.min(viewportExtent, math.max(rowExtent, target));
  }

  static bool shouldPrefetch({
    required double extentAfter,
    required double viewportExtent,
    required double rowExtent,
    required bool isLoading,
    required bool hasMore,
  }) {
    if (isLoading || !hasMore || !extentAfter.isFinite) return false;
    final threshold = calculateThreshold(
      viewportExtent: viewportExtent,
      rowExtent: rowExtent,
    );
    return threshold > 0 && extentAfter <= threshold;
  }
}
