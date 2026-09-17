import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/playback_first_frame.dart';
import 'package:selene/ui/player/video_output_readiness.dart';

void main() {
  testWidgets('上游首帧 Future 提前完成时，占位纹理不能结束 loading', (tester) async {
    var rect = const Rect.fromLTWH(0, 0, 1, 1);
    var ready = false;
    final gate = PlaybackFirstFrame(
      waitForOutput: () async {},
      isOutputReady: () async => isVideoOutputUsable(
        textureId: 0,
        textureRect: rect,
        videoWidth: 1920,
        videoHeight: 1080,
      ),
      waitForPresentation: () async {},
    );
    addTearDown(gate.dispose);
    final completion = gate.wait().then((_) => ready = true);
    await tester.pump();
    expect(ready, isFalse);

    rect = const Rect.fromLTWH(0, 0, 1920, 1080);
    await tester.pump(const Duration(milliseconds: 50));
    await completion;
    expect(ready, isTrue);
  });

  test('纹理创建与视频宽高缺一不可，纹理 ID 0 合法', () {
    bool usable(int? id, Rect? rect, int? width, int? height) =>
        isVideoOutputUsable(
          textureId: id,
          textureRect: rect,
          videoWidth: width,
          videoHeight: height,
        );
    const rect = Rect.fromLTWH(0, 0, 640, 360);
    expect(usable(0, rect, 640, 360), isTrue);
    expect(usable(null, rect, 640, 360), isFalse);
    expect(usable(-1, rect, 640, 360), isFalse);
    expect(usable(0, null, 640, 360), isFalse);
    expect(usable(0, rect, null, 360), isFalse);
    expect(usable(0, rect, 640, 0), isFalse);
  });

  test('拒绝无效尺寸，但不误伤合法的细长视频', () {
    bool usable(Rect rect) => isVideoOutputUsable(
      textureId: 1,
      textureRect: rect,
      videoWidth: 1,
      videoHeight: 360,
    );
    expect(usable(const Rect.fromLTWH(0, 0, 1, 360)), isTrue);
    expect(usable(Rect.zero), isFalse);
    expect(usable(const Rect.fromLTWH(0, 0, -1, 360)), isFalse);
    expect(usable(const Rect.fromLTWH(0, 0, double.infinity, 360)), isFalse);
    expect(usable(const Rect.fromLTWH(0, 0, double.nan, 360)), isFalse);
  });
}
