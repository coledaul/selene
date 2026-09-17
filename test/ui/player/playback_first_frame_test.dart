import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/playback_first_frame.dart';

void main() {
  testWidgets('尺寸就绪不结束等待，原生输出和 Flutter 帧均完成后才就绪', (tester) async {
    final output = Completer<void>();
    final presentation = Completer<void>();
    var rendered = false;
    var presentationRequests = 0;
    final gate = PlaybackFirstFrame(
      waitForOutput: () => output.future,
      isOutputReady: () async => rendered,
      waitForPresentation: () {
        presentationRequests++;
        return presentation.future;
      },
    );
    addTearDown(gate.dispose);
    var ready = false;
    final wait = gate.wait().then((_) => ready = true);
    output.complete();
    await tester.pump();
    expect(ready, isFalse);
    expect(presentationRequests, 0);

    rendered = true;
    await tester.pump(const Duration(milliseconds: 50));
    expect(ready, isFalse);
    expect(presentationRequests, 1);
    presentation.complete();
    await tester.pump();
    await wait;
    expect(ready, isTrue);
  });

  testWidgets('释放取消未完成的输出等待，迟到事件不继续读取', (tester) async {
    final output = Completer<void>();
    var probes = 0;
    final gate = PlaybackFirstFrame(
      waitForOutput: () => output.future,
      isOutputReady: () async {
        probes++;
        return true;
      },
      waitForPresentation: () async {},
    );
    final result = expectLater(gate.wait(), throwsStateError);
    gate.dispose();
    output.complete();
    await tester.pump();
    await result;
    expect(probes, 0);
  });

  testWidgets('首帧超时明确失败并停止轮询', (tester) async {
    var probes = 0;
    final gate = PlaybackFirstFrame(
      waitForOutput: () async {},
      isOutputReady: () async {
        probes++;
        return false;
      },
      waitForPresentation: () async {},
      timeout: const Duration(milliseconds: 100),
    );
    final result = expectLater(gate.wait(), throwsA(isA<TimeoutException>()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await result;
    final stoppedAt = probes;
    await tester.pump(const Duration(seconds: 1));
    expect(probes, stoppedAt);
  });

  testWidgets('底层错误原样传出，不伪造首帧成功', (tester) async {
    final gate = PlaybackFirstFrame(
      waitForOutput: () async {},
      isOutputReady: () async => throw const FormatException(),
      waitForPresentation: () async {},
    );
    await expectLater(gate.wait(), throwsFormatException);
  });

  testWidgets('等待 Flutter 帧期间输出失效时继续等待', (tester) async {
    var rendered = true;
    final presentation = Completer<void>();
    final gate = PlaybackFirstFrame(
      waitForOutput: () async {},
      isOutputReady: () async => rendered,
      waitForPresentation: () => presentation.future,
    );
    var ready = false;
    final wait = gate.wait().then((_) => ready = true);
    await tester.pump();
    rendered = false;
    presentation.complete();
    await tester.pump();
    expect(ready, isFalse);
    rendered = true;
    await tester.pump(const Duration(milliseconds: 50));
    await wait;
    expect(ready, isTrue);
  });
}
