import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/native_video_frame_probe.dart';

void main() {
  late Map<String, String> properties;
  late NativeVideoFrameProbe probe;
  setUp(() {
    properties = {
      'current-vo': 'gpu',
      'vo-passes': '{"fresh":[{"desc":"output"}],"redraw":[]}',
      'core-idle': 'no',
      'seeking': 'no',
    };
    probe = NativeVideoFrameProbe((name) async => properties[name] ?? '');
  });

  test('GPU 新视频帧已绘制且启动或 seek 完成才就绪', () async {
    expect(await probe.hasRenderedFrame(), isTrue);
  });

  test('仅输出初始化、背景重绘或尚无渲染数据不能冒充视频帧', () async {
    for (final value in ['', '{"fresh":[],"redraw":[{}]}']) {
      properties['vo-passes'] = value;
      expect(await probe.hasRenderedFrame(), isFalse);
    }
  });

  test('Surface 重建时的空输出不得提前结束 loading', () async {
    properties['current-vo'] = 'null';
    expect(await probe.hasRenderedFrame(), isFalse);
  });

  test('原生播放器仍在启动或跳转时不能放行', () async {
    properties['core-idle'] = 'yes';
    expect(await probe.hasRenderedFrame(), isFalse);
    properties['core-idle'] = 'no';
    properties['seeking'] = 'yes';
    expect(await probe.hasRenderedFrame(), isFalse);
    properties['seeking'] = '';
    expect(await probe.hasRenderedFrame(), isFalse);
  });

  test('读取异常和格式错误明确失败', () async {
    properties['vo-passes'] = 'invalid';
    await expectLater(probe.hasRenderedFrame(), throwsFormatException);
    final failing = NativeVideoFrameProbe(
      (_) async => throw StateError('read'),
    );
    await expectLater(failing.hasRenderedFrame(), throwsStateError);
  });
}
