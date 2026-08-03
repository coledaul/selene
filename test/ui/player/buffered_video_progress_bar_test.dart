import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/video_playback_session.dart';
import 'package:selene/ui/player/widgets/buffered_video_progress_bar.dart';

void main() {
  testWidgets('绘制多个实际可寻址缓存范围并保持播放进度在上层', (tester) async {
    await tester.pumpWidget(
      _host(
        BufferedVideoProgressBar(
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 100),
          cachedRanges: const <PlaybackBufferedRange>[
            PlaybackBufferedRange(
              start: Duration.zero,
              end: Duration(seconds: 20),
            ),
            PlaybackBufferedRange(
              start: Duration(seconds: 40),
              end: Duration(seconds: 60),
            ),
          ],
          onSeekRequested: (_) async {},
        ),
      ),
    );

    final painter =
        tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
            as BufferedVideoProgressPainter;
    expect(painter.cachedRanges, hasLength(2));
    expect(painter.position, const Duration(seconds: 30));
    expect(painter.duration, const Duration(seconds: 100));
    expect(painter.layerOrder, const <PlaybackProgressLayer>[
      PlaybackProgressLayer.background,
      PlaybackProgressLayer.buffered,
      PlaybackProgressLayer.played,
      PlaybackProgressLayer.thumb,
    ]);
  });

  testWidgets('拖动过程只更新预览，松手只提交一次 Seek', (tester) async {
    final previews = <Duration>[];
    final seeks = <Duration>[];
    await tester.pumpWidget(
      _host(
        BufferedVideoProgressBar(
          position: Duration.zero,
          duration: const Duration(seconds: 100),
          cachedRanges: const <PlaybackBufferedRange>[],
          onPreviewChanged: previews.add,
          onSeekRequested: (position) async => seeks.add(position),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byType(BufferedVideoProgressBar)) +
          const Offset(10, 12),
    );
    await gesture.moveBy(const Offset(80, 0));
    await gesture.moveBy(const Offset(60, 0));
    expect(previews.length, greaterThan(1));
    expect(seeks, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(seeks, hasLength(1));
    expect(seeks.single.inSeconds, inInclusiveRange(70, 80));
  });

  testWidgets('点击只提交一次 Seek', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      _host(
        BufferedVideoProgressBar(
          position: Duration.zero,
          duration: const Duration(seconds: 100),
          cachedRanges: const <PlaybackBufferedRange>[],
          onSeekRequested: (position) async => seeks.add(position),
        ),
      ),
    );

    await tester.tapAt(
      tester.getTopLeft(find.byType(BufferedVideoProgressBar)) +
          const Offset(100, 12),
    );
    await tester.pump();

    expect(seeks, hasLength(1));
    expect(seeks.single.inSeconds, inInclusiveRange(45, 55));
  });

  testWidgets('直播时间轴不响应点击或拖动且不绘制把手', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      _host(
        BufferedVideoProgressBar(
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 100),
          cachedRanges: const <PlaybackBufferedRange>[],
          live: true,
          onSeekRequested: (position) async => seeks.add(position),
        ),
      ),
    );

    await tester.tap(find.byType(BufferedVideoProgressBar));
    await tester.drag(
      find.byType(BufferedVideoProgressBar),
      const Offset(120, 0),
    );
    await tester.pump();

    final painter =
        tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
            as BufferedVideoProgressPainter;
    expect(seeks, isEmpty);
    expect(painter.live, isTrue);
  });

  testWidgets('极窄约束下把手退化到可绘制位置且不会抛出异常', (tester) async {
    await tester.pumpWidget(
      _host(
        BufferedVideoProgressBar(
          position: const Duration(seconds: 50),
          duration: const Duration(seconds: 100),
          cachedRanges: const <PlaybackBufferedRange>[],
          onSeekRequested: (_) async {},
        ),
        width: 8,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Widget _host(Widget child, {double width = 200}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, height: 24, child: child),
    ),
  ),
);
