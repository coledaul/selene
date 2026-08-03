import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../video_playback_session.dart';

enum BufferedVideoProgressStyle { mobile, desktop }

enum PlaybackProgressLayer { background, buffered, played, thumb }

/// 移动端与桌面端共用的缓存时间轴，只在点击或拖动结束时提交 Seek。
final class BufferedVideoProgressBar extends StatefulWidget {
  const BufferedVideoProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.cachedRanges,
    required this.onSeekRequested,
    this.live = false,
    this.style = BufferedVideoProgressStyle.mobile,
    this.isSeekingViaSwipe = false,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.onInteractionEnd,
    this.onPreviewChanged,
  });

  final Duration position;
  final Duration duration;
  final List<PlaybackBufferedRange> cachedRanges;
  final Future<void> Function(Duration position) onSeekRequested;
  final bool live;
  final BufferedVideoProgressStyle style;
  final bool isSeekingViaSwipe;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionUpdate;
  final VoidCallback? onInteractionEnd;
  final ValueChanged<Duration>? onPreviewChanged;

  @override
  State<BufferedVideoProgressBar> createState() =>
      _BufferedVideoProgressBarState();
}

final class _BufferedVideoProgressBarState
    extends State<BufferedVideoProgressBar> {
  bool _dragging = false;
  bool _seeking = false;
  bool _hovering = false;
  double _dragFraction = 0;
  double _width = 0;

  Duration get _displayPosition {
    if (_dragging && widget.duration > Duration.zero) {
      return Duration(
        microseconds: (widget.duration.inMicroseconds * _dragFraction).round(),
      );
    }
    return widget.position;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = widget.style == BufferedVideoProgressStyle.desktop;
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return MouseRegion(
          cursor: widget.live ? MouseCursor.defer : SystemMouseCursors.click,
          onEnter: desktop ? (_) => setState(() => _hovering = true) : null,
          onExit: desktop ? (_) => setState(() => _hovering = false) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.live ? null : _handleTap,
            onHorizontalDragStart: widget.live ? null : _handleDragStart,
            onHorizontalDragUpdate: widget.live ? null : _handleDragUpdate,
            onHorizontalDragEnd: widget.live ? null : _handleDragEnd,
            onHorizontalDragCancel: widget.live ? null : _handleDragCancel,
            child: SizedBox.expand(
              child: CustomPaint(
                painter: BufferedVideoProgressPainter(
                  position: _displayPosition,
                  duration: widget.duration,
                  cachedRanges: widget.cachedRanges,
                  live: widget.live,
                  trackHeight: desktop ? 4 : 6,
                  thumbRadius: desktop
                      ? (_hovering || _dragging || _seeking ? 7 : 5)
                      : (widget.isSeekingViaSwipe || _dragging || _seeking
                            ? 9
                            : 8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragging = true;
      _dragFraction = _fractionFor(details.localPosition.dx);
    });
    widget.onInteractionStart?.call();
    _publishPreview();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    setState(() => _dragFraction = _fractionFor(details.localPosition.dx));
    widget.onInteractionUpdate?.call();
    _publishPreview();
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (!_dragging) return;
    final target = _positionForFraction(_dragFraction);
    setState(() {
      _dragging = false;
      _seeking = true;
    });
    try {
      await widget.onSeekRequested(target);
    } finally {
      if (mounted) setState(() => _seeking = false);
      widget.onInteractionEnd?.call();
    }
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    widget.onInteractionEnd?.call();
  }

  Future<void> _handleTap(TapUpDetails details) async {
    final target = _positionForFraction(_fractionFor(details.localPosition.dx));
    widget.onInteractionStart?.call();
    widget.onPreviewChanged?.call(target);
    setState(() => _seeking = true);
    try {
      await widget.onSeekRequested(target);
    } finally {
      if (mounted) setState(() => _seeking = false);
      widget.onInteractionEnd?.call();
    }
  }

  double _fractionFor(double dx) {
    if (_width <= 0) return 0;
    return (dx / _width).clamp(0.0, 1.0);
  }

  Duration _positionForFraction(double fraction) {
    if (widget.duration <= Duration.zero) return Duration.zero;
    return Duration(
      microseconds: (widget.duration.inMicroseconds * fraction).round(),
    );
  }

  void _publishPreview() {
    widget.onPreviewChanged?.call(_positionForFraction(_dragFraction));
  }
}

final class BufferedVideoProgressPainter extends CustomPainter {
  const BufferedVideoProgressPainter({
    required this.position,
    required this.duration,
    required this.cachedRanges,
    required this.live,
    required this.trackHeight,
    required this.thumbRadius,
  });

  final Duration position;
  final Duration duration;
  final List<PlaybackBufferedRange> cachedRanges;
  final bool live;
  final double trackHeight;
  final double thumbRadius;

  List<PlaybackProgressLayer> get layerOrder => const <PlaybackProgressLayer>[
    PlaybackProgressLayer.background,
    PlaybackProgressLayer.buffered,
    PlaybackProgressLayer.played,
    PlaybackProgressLayer.thumb,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final top = (size.height - trackHeight) / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, size.width, trackHeight),
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(
      track,
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );

    if (duration > Duration.zero && !live) {
      final bufferedPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.48);
      for (final range in cachedRanges) {
        final start = _fraction(range.start);
        final end = _fraction(range.end);
        if (end <= start) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * start,
              top,
              size.width * (end - start),
              trackHeight,
            ),
            Radius.circular(trackHeight / 2),
          ),
          bufferedPaint,
        );
      }

      final played = _fraction(position);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, size.width * played, trackHeight),
          Radius.circular(trackHeight / 2),
        ),
        Paint()..color = Colors.red,
      );
      final thumbInset = thumbRadius > size.width / 2
          ? size.width / 2
          : thumbRadius;
      final thumbX = (size.width * played).clamp(
        thumbInset,
        size.width - thumbInset,
      );
      canvas.drawCircle(
        Offset(thumbX, size.height / 2),
        thumbRadius,
        Paint()..color = Colors.red,
      );
    }
  }

  double _fraction(Duration value) {
    if (duration <= Duration.zero) return 0;
    return (value.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant BufferedVideoProgressPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.duration != duration ||
      !listEquals(oldDelegate.cachedRanges, cachedRanges) ||
      oldDelegate.live != live ||
      oldDelegate.trackHeight != trackHeight ||
      oldDelegate.thumbRadius != thumbRadius;
}
