import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:selene/ui/player/video_playback_session.dart';
import 'package:selene/ui/player/widgets/video_player_surface.dart';
import 'package:selene/ui/player/widgets/video_player_widget.dart';

void main() {
  testWidgets('首次打开、全屏换源与全屏重试都绑定新纹理并恢复全屏', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.alexmercerind/media_kit_video'),
          (_) async => null,
        );
    final engines = <_Engine>[];
    late VideoPlayerWidgetController controller;
    var readyCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoPlayerWidget(
            surface: VideoPlayerSurface.desktop,
            onControllerCreated: (value) => controller = value,
            onReady: () => readyCount++,
            sessionFactory: () {
              final engine = _Engine(engines.length + 1);
              engines.add(engine);
              return VideoPlaybackSession(engine: engine);
            },
          ),
        ),
      ),
    );
    final emptyVideoState = tester.state(find.byType(Video));
    expect(find.byType(Texture), findsNothing);

    for (var index = 1; index <= 3; index++) {
      final oldEngine = engines.last;
      final previousState = tester.state(find.byType(Video));
      if (index == 2) {
        await tester.runAsync(
          () => (previousState as VideoState).enterFullscreen(),
        );
        await tester.pump();
        expect(find.byType(Video, skipOffstage: false), findsNWidgets(2));
      }
      if (index == 3) {
        await tester.runAsync(() async {
          oldEngine.errorEvents.add('decode failed');
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pump();
        await tester.pump();
        expect(find.text('重试'), findsOneWidget);
        await tester.tap(find.text('重试'));
      } else {
        await tester.runAsync(() async {
          unawaited(
            controller.updateDataSource(
              PlaybackMediaSource(
                url: 'https://example.com/$index.mp4',
                kind: PlaybackMediaKind.networkVod,
              ),
            ),
          );
        });
      }
      for (var frame = 0; frame < 20 && engines.length <= index; frame++) {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(engines.length, index + 1);
      await tester.pump();
      expect(oldEngine.disposed, isTrue);
      expect(tester.state(find.byType(Video)), isNot(same(previousState)));
      expect(tester.state(find.byType(Video)), isNot(same(emptyVideoState)));

      final engine = engines.last;
      engine.controller.player.setSize(640, 360);
      await tester.pump();
      await tester.pump();
      expect(find.byType(Texture), findsOneWidget);
      expect(tester.widget<Texture>(find.byType(Texture)).textureId, index + 1);
      expect(readyCount, index - 1);
      await tester.runAsync(() async {
        engine.frame.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump();
      expect(readyCount, index);
      if (index >= 2) {
        expect(find.byType(Video, skipOffstage: false), findsNWidgets(2));
        final fullscreen = tester.state<VideoState>(find.byType(Video));
        expect(fullscreen.isFullscreen(), isTrue);
        if (index == 3) {
          await tester.runAsync(fullscreen.exitFullscreen);
          await tester.pump();
        }
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    for (final engine in engines) {
      unawaited(engine.controller.player.stream.close());
      unawaited(engine.errorEvents.close());
      engine.controller.notifier.dispose();
      engine.controller.output.id.dispose();
      engine.controller.output.rect.dispose();
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _Engine extends Fake implements PlaybackEngine {
  _Engine(int textureId) : controller = _Controller(textureId);
  final _Controller controller;
  final frame = Completer<void>();
  final errorEvents = StreamController<String>.broadcast();
  bool disposed = false;

  @override
  VideoController get videoController => controller;
  @override
  double get rate => 1;
  @override
  double get volume => 100;
  @override
  bool get supportsNativeCacheProperties => false;
  @override
  bool get buffering => false;
  @override
  Stream<Duration> get positions => const Stream.empty();
  @override
  Stream<Duration> get durations => const Stream.empty();
  @override
  Stream<bool> get playingChanges => const Stream.empty();
  @override
  Stream<bool> get bufferingChanges => const Stream.empty();
  @override
  Stream<bool> get completedChanges => const Stream.empty();
  @override
  Stream<String> get errors => errorEvents.stream;
  @override
  Future<void> stop() async {}
  @override
  Future<void> open(
    String url, {
    required Map<String, String> headers,
    Duration? startAt,
  }) async {}
  @override
  Future<void> setRate(double rate) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> waitUntilFirstFrameRendered() => frame.future;
  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _Controller extends Fake implements VideoController {
  _Controller(int id) : output = _Output(id) {
    notifier = ValueNotifier(output);
  }
  final _Output output;
  @override
  final _Player player = _Player();
  @override
  late final ValueNotifier<PlatformVideoController?> notifier;
}

class _Output extends Fake implements PlatformVideoController {
  _Output(int textureId) : id = ValueNotifier(textureId);
  @override
  final ValueNotifier<int?> id;
  @override
  final rect = ValueNotifier<Rect?>(const Rect.fromLTWH(0, 0, 640, 360));
}

class _Player extends Fake implements Player {
  @override
  PlayerState state = PlayerState();
  @override
  PlatformPlayer? get platform => null;
  @override
  final _Streams stream = _Streams();

  void setSize(int width, int height) {
    state = state.copyWith(width: width, height: height);
    stream.widthEvents.add(width);
    stream.heightEvents.add(height);
  }
}

class _Streams extends Fake implements PlayerStream {
  final widthEvents = StreamController<int?>.broadcast();
  final heightEvents = StreamController<int?>.broadcast();
  @override
  Stream<int?> get width => widthEvents.stream;
  @override
  Stream<int?> get height => heightEvents.stream;
  @override
  Stream<bool> get playing => const Stream.empty();
  @override
  Stream<List<String>> get subtitle => const Stream.empty();
  Future<void> close() async {
    await widthEvents.close();
    await heightEvents.close();
  }
}
