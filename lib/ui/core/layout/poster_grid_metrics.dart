import 'dart:math' as math;

/// 海报网格的统一尺寸规则。
final class PosterGridMetrics {
  const PosterGridMetrics._({
    required this.itemWidth,
    required this.itemHeight,
    required this.mainAxisSpacing,
  });

  static const double horizontalPadding = 16;
  static const double crossAxisSpacing = 12;
  static const double phoneMainAxisSpacing = 6;
  static const double minItemWidth = 80;
  static const double itemHeightFactor = 2;

  final double itemWidth;
  final double itemHeight;
  final double mainAxisSpacing;

  double get rowExtent => itemHeight + mainAxisSpacing;

  static PosterGridMetrics calculate({
    required double availableWidth,
    required int crossAxisCount,
    required bool isTablet,
  }) {
    assert(availableWidth >= 0);
    assert(crossAxisCount > 0);

    final contentWidth =
        availableWidth -
        (horizontalPadding * 2) -
        (crossAxisSpacing * (crossAxisCount - 1));
    final itemWidth = math.max(contentWidth / crossAxisCount, minItemWidth);
    final mainAxisSpacing = isTablet ? 0.0 : phoneMainAxisSpacing;
    return PosterGridMetrics._(
      itemWidth: itemWidth,
      itemHeight: itemWidth * itemHeightFactor,
      mainAxisSpacing: mainAxisSpacing,
    );
  }
}
