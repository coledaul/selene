import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:selene/ui/player/video_playback_session.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('PlaybackCachePolicy', () {
    test('为点播、直播和本地文件生成互斥的显式缓存属性', () {
      final vod = PlaybackCachePolicy.forMediaKind(
        PlaybackMediaKind.networkVod,
      );
      final live = PlaybackCachePolicy.forMediaKind(PlaybackMediaKind.live);
      final local = PlaybackCachePolicy.forMediaKind(
        PlaybackMediaKind.localFile,
      );

      expect(vod.properties, containsPair('cache', 'yes'));
      expect(vod.properties, containsPair('cache-on-disk', 'yes'));
      expect(vod.properties, containsPair('cache-secs', '180'));
      expect(vod.properties, containsPair('demuxer-max-bytes', '32MiB'));
      expect(vod.properties, containsPair('demuxer-max-back-bytes', '128MiB'));
      expect(
        vod.properties,
        containsPair('demuxer-cache-unlink-files', 'immediate'),
      );
      expect(vod.maxDiskCacheBytes, 1024 * 1024 * 1024);

      expect(live.properties, containsPair('cache', 'yes'));
      expect(live.properties, containsPair('cache-on-disk', 'no'));
      expect(live.properties, containsPair('cache-secs', '10'));
      expect(live.properties, containsPair('demuxer-max-back-bytes', '0'));
      expect(live.maxDiskCacheBytes, isNull);

      expect(local.properties, containsPair('cache', 'no'));
      expect(local.properties, containsPair('cache-on-disk', 'no'));
      expect(local.maxDiskCacheBytes, isNull);
    });
  });

  group('PlaybackCacheSnapshot', () {
    test('裁剪、排序并合并乱序、重叠和紧邻的缓存范围', () {
      final snapshot = PlaybackCacheSnapshot.tryParse(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 10, 'end': 20},
            <String, Object>{'start': -3, 'end': 5},
            <String, Object>{'start': 4.9, 'end': 12},
            <String, Object>{'start': 40, 'end': 40},
            <String, Object>{'start': 90, 'end': 150},
          ],
          'bof-cached': true,
          'eof-cached': true,
          'file-cache-bytes': 4096,
          'reader-pts': 1.5,
          'cache-end': 101.0,
          'raw-input-rate': 2048,
        }),
        duration: const Duration(seconds: 100),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.ranges, <PlaybackBufferedRange>[
        const PlaybackBufferedRange(
          start: Duration.zero,
          end: Duration(seconds: 20),
        ),
        const PlaybackBufferedRange(
          start: Duration(seconds: 90),
          end: Duration(seconds: 100),
        ),
      ]);
      expect(snapshot.beginningOfFileCached, isTrue);
      expect(snapshot.endOfFileCached, isTrue);
      expect(snapshot.fileCacheBytes, 4096);
      expect(snapshot.readerPosition, const Duration(milliseconds: 1500));
      expect(snapshot.cacheEnd, const Duration(seconds: 100));
      expect(snapshot.rawInputRate, 2048);
    });

    test('畸形 JSON、错误字段类型和非有限时间不会抛出', () {
      expect(
        PlaybackCacheSnapshot.tryParse(
          'not-json',
          duration: const Duration(minutes: 1),
        ),
        isNull,
      );
      expect(
        PlaybackCacheSnapshot.tryParse(
          jsonEncode(<String, Object>{'seekable-ranges': 'invalid'}),
          duration: const Duration(minutes: 1),
        ),
        isNull,
      );
      expect(
        PlaybackCacheSnapshot.tryParse(
          '{"seekable-ranges":[{"start":1e999,"end":20}]}',
          duration: const Duration(minutes: 1),
        ),
        isNull,
      );
    });
  });

  group('VideoPlaybackSession', () {
    late _FakePlaybackEngine engine;
    late VideoPlaybackSession session;
    late List<String> diagnostics;

    setUp(() {
      engine = _FakePlaybackEngine();
      diagnostics = <String>[];
      session = VideoPlaybackSession(
        engine: engine,
        diagnostic: (event, error) {
          diagnostics.add('$event:${error.runtimeType}');
        },
      );
    });

    tearDown(() async {
      await session.disposeSession();
      await engine.closeStreams();
    });

    test('打开前先关闭旧媒体、应用缓存策略并开始观察', () async {
      await session.open(
        'https://example.com/video.m3u8',
        kind: PlaybackMediaKind.networkVod,
        headers: const <String, String>{'Authorization': 'secret'},
      );

      final stopIndex = engine.calls.indexOf('stop');
      final configureIndex = engine.calls.indexOf('set:cache=yes');
      final observeIndex = engine.calls.indexOf('observe');
      final openIndex = engine.calls.indexOf('open');
      expect(stopIndex, greaterThanOrEqualTo(0));
      expect(configureIndex, greaterThan(stopIndex));
      expect(observeIndex, greaterThan(configureIndex));
      expect(openIndex, greaterThan(observeIndex));
      expect(engine.openedUrls, <String>['https://example.com/video.m3u8']);
      expect(engine.openedHeaders.single, const <String, String>{
        'Authorization': 'secret',
      });
    });

    test('从目标进度打开媒体而不是先从零打开后再次 Seek', () async {
      await session.open(
        'https://example.com/video.m3u8',
        kind: PlaybackMediaKind.networkVod,
        startAt: const Duration(minutes: 18),
      );

      expect(engine.openedStartAts, <Duration?>[const Duration(minutes: 18)]);
      expect(engine.calls.where((call) => call.startsWith('seek:')), isEmpty);
    });

    test('快速换源后旧 generation 的缓存事件不能覆盖新状态', () async {
      final firstOpenGate = Completer<void>();
      engine.openGate = firstOpenGate;
      final firstOpen = session.open(
        'https://example.com/first.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      await _flushEvents();
      final oldListener = engine.cacheListeners.single;

      final secondOpen = session.open(
        'https://example.com/second.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      firstOpenGate.complete();
      await firstOpen;
      await secondOpen;
      engine.emitDuration(const Duration(seconds: 100));
      await _flushEvents();

      await oldListener(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 0, 'end': 90},
          ],
          'file-cache-bytes': 9000,
        }),
      );

      expect(session.state.cachedRanges, isEmpty);
      expect(session.state.temporaryCacheBytes, 0);
      expect(engine.openedUrls.last, 'https://example.com/second.mp4');
    });

    test('换源后旧源播放命令失败不能污染新源状态', () async {
      await session.open(
        'https://example.com/first.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      final playGate = Completer<void>();
      engine
        ..playGate = playGate
        ..failingPlay = true;

      final oldPlay = session.play();
      await _flushEvents();
      final secondOpen = session.open(
        'https://example.com/second.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      playGate.complete();

      await oldPlay;
      await secondOpen;

      expect(session.state.failure, isNull);
      expect(session.state.opening, isTrue);
      expect(engine.openedUrls.last, 'https://example.com/second.mp4');
    });

    test('新源打开请求立即清空旧源缓存状态', () async {
      await session.open(
        'https://example.com/first.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(seconds: 100));
      await _flushEvents();
      await engine.cacheListeners.single(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 0, 'end': 30},
          ],
          'file-cache-bytes': 8192,
        }),
      );
      expect(session.state.cachedRanges, isNotEmpty);

      final secondOpen = session.open(
        'https://example.com/second.mp4',
        kind: PlaybackMediaKind.networkVod,
      );

      expect(session.state.cachedRanges, isEmpty);
      expect(session.state.temporaryCacheBytes, 0);
      expect(session.state.opening, isTrue);
      await secondOpen;
    });

    test('换源未提供请求头时沿用当前媒体请求头', () async {
      await session.open(
        'https://example.com/first.m3u8',
        kind: PlaybackMediaKind.networkVod,
        headers: const <String, String>{'Referer': 'https://example.com'},
      );

      await session.open(
        'https://example.com/second.m3u8',
        kind: PlaybackMediaKind.networkVod,
      );

      expect(engine.openedHeaders.last, const <String, String>{
        'Referer': 'https://example.com',
      });
    });

    test('磁盘缓存达到 1 GiB 后停止新增磁盘写入并暴露存储降级', () async {
      await session.open(
        'https://example.com/large.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(hours: 3));
      await _flushEvents();

      await engine.cacheListeners.single(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 0, 'end': 600},
          ],
          'file-cache-bytes': 1024 * 1024 * 1024,
        }),
      );

      expect(engine.calls, contains('set:cache-on-disk=no'));
      expect(session.state.cacheLimitReached, isTrue);
      expect(session.state.warning?.kind, FailureKind.storage);
      expect(session.state.failure, isNull);
      expect(session.state.temporaryCacheBytes, 1024 * 1024 * 1024);
    });

    test('缓存配置失败时仍打开媒体并形成不含地址的降级诊断', () async {
      engine.failingProperty = 'cache-secs';

      await session.open(
        'https://example.com/signed.mp4?token=private',
        kind: PlaybackMediaKind.networkVod,
      );

      expect(engine.openedUrls, hasLength(1));
      expect(diagnostics.join('\n'), isNot(contains('example.com')));
      expect(diagnostics.join('\n'), isNot(contains('token')));
      expect(diagnostics.join('\n'), isNot(contains('private')));
      expect(session.state.warning?.message, contains('缓存配置'));
      expect(session.state.failure, isNull);
    });

    test('缓存状态观察失败是非致命降级且仍会打开媒体', () async {
      engine.failingObserve = true;

      await session.open(
        'https://example.com/video.m3u8',
        kind: PlaybackMediaKind.networkVod,
      );

      expect(engine.calls, contains('open'));
      expect(session.state.warning?.message, contains('缓存范围'));
      expect(session.state.failure, isNull);
    });

    test('主动快照不能冒充持续观察，收到真实观察事件后清除降级', () async {
      await session.open(
        'https://example.com/video.m3u8',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(minutes: 1));
      await _flushEvents();

      expect(session.state.warning?.message, contains('持续更新'));

      await engine.cacheListeners.single(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 0, 'end': 10},
          ],
        }),
      );

      expect(session.state.warning, isNull);
      expect(session.state.cachedRanges, isNotEmpty);
    });

    test('duration ready 前的缓存事件不会阻止 ready 后重新读取范围', () async {
      await session.open(
        'https://example.com/video.m3u8',
        kind: PlaybackMediaKind.networkVod,
      );
      await engine.cacheListeners.single(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 0, 'end': 20},
          ],
        }),
      );
      expect(session.state.cachedRanges, isEmpty);

      engine.cacheState = jsonEncode(<String, Object>{
        'seekable-ranges': <Object>[
          <String, Object>{'start': 0, 'end': 20},
        ],
      });
      engine.emitDuration(const Duration(seconds: 100));
      await _flushEvents();

      expect(session.state.cachedRanges, const <PlaybackBufferedRange>[
        PlaybackBufferedRange(start: Duration.zero, end: Duration(seconds: 20)),
      ]);
    });

    test('ready 后播放错误仍暴露可重试失败', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(minutes: 1));
      await _flushEvents();

      engine.emitError('contains-sensitive-url');
      await _flushEvents();

      expect(session.state.ready, isTrue);
      expect(session.state.failure?.message, '视频播放发生错误，请重试');
      expect(session.state.failureRetryable, isTrue);
      expect(diagnostics.join('\n'), isNot(contains('contains-sensitive-url')));
    });

    test('ready 后播放错误从真实当前位置重试而不是退回初始续播点', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
        startAt: const Duration(minutes: 5),
      );
      engine.emitDuration(const Duration(minutes: 30));
      engine.emitPosition(const Duration(minutes: 12));
      await _flushEvents();
      engine.emitError('playback failed');
      await _flushEvents();

      await session.retryCurrent();

      expect(engine.openedStartAts.last, const Duration(minutes: 12));
    });

    test('缓存内 Seek 不进入重新缓冲，缓存外 Seek 明确进入缓冲', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(seconds: 100));
      await _flushEvents();
      await engine.cacheListeners.single(
        jsonEncode(<String, Object>{
          'seekable-ranges': <Object>[
            <String, Object>{'start': 0, 'end': 20},
          ],
        }),
      );

      await session.seek(const Duration(seconds: 10));
      expect(session.state.buffering, isFalse);

      await session.seek(const Duration(seconds: 50));
      expect(session.state.buffering, isTrue);
    });

    test('Seek 失败时恢复播放器真实位置并暴露明确错误', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(seconds: 100));
      await _flushEvents();
      await session.seek(const Duration(seconds: 12));
      engine.failingSeek = true;

      await session.seek(const Duration(seconds: 50));

      expect(session.state.position, const Duration(seconds: 12));
      expect(session.state.buffering, isFalse);
      expect(session.state.failure?.message, '跳转失败，请重试');
    });

    test('播放完成后重播只调用 seek(0) 和 play，不重新 open', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(seconds: 100));
      engine.emitCompleted(true);
      await _flushEvents();
      final openCount = engine.calls.where((call) => call == 'open').length;

      await session.replay();

      expect(
        engine.calls.where((call) => call == 'open'),
        hasLength(openCount),
      );
      expect(engine.calls, contains('seek:0'));
      expect(engine.calls, contains('play'));
      expect(session.state.completed, isFalse);
    });

    test('重播 Seek 期间换源后不会继续对新源执行旧重播命令', () async {
      await session.open(
        'https://example.com/first.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitCompleted(true);
      await _flushEvents();
      final seekGate = Completer<void>();
      engine.seekGate = seekGate;

      final replay = session.replay();
      await _flushEvents();
      expect(engine.calls, contains('seek:0'));
      final secondOpen = session.open(
        'https://example.com/second.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      seekGate.complete();

      await replay;
      await secondOpen;

      expect(engine.calls.where((call) => call == 'play'), isEmpty);
      expect(engine.openedUrls.last, 'https://example.com/second.mp4');
    });

    test('重播复位完成态后第二次到达结尾仍可再次完成', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      engine.emitDuration(const Duration(seconds: 100));
      engine.emitCompleted(true);
      await _flushEvents();

      await session.replay();
      engine.emitCompleted(false);
      engine.emitCompleted(true);
      await _flushEvents();

      expect(session.state.completed, isTrue);
    });

    test('倍速与音量由会话状态统一维护', () async {
      await session.setRate(1.5);
      await session.setVolume(35);

      expect(session.state.rate, 1.5);
      expect(session.state.volume, 35);
    });

    test('倍速与音量并发设置以最新请求为准且立即更新期望状态', () async {
      final rateGate = Completer<void>();
      final volumeGate = Completer<void>();
      engine
        ..rateGate = rateGate
        ..volumeGate = volumeGate;

      final firstRate = session.setRate(1.25);
      final firstVolume = session.setVolume(25);
      expect(session.state.rate, 1.25);
      expect(session.state.volume, 25);

      final latestRate = session.setRate(1.5);
      final latestVolume = session.setVolume(80);
      expect(session.state.rate, 1.5);
      expect(session.state.volume, 80);
      rateGate.complete();
      volumeGate.complete();

      await Future.wait(<Future<void>>[
        firstRate,
        latestRate,
        firstVolume,
        latestVolume,
      ]);

      expect(session.state.rate, 1.5);
      expect(session.state.volume, 80);
      expect(engine.rate, 1.5);
      expect(engine.volume, 80);
    });

    test('释放顺序为取消观察、取消流订阅、最后释放播放器', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );

      await session.disposeSession();

      final unobserveIndex = engine.calls.indexOf('unobserve');
      final cancelIndex = engine.calls.indexWhere(
        (call) => call.startsWith('cancel:'),
      );
      final disposeIndex = engine.calls.indexOf('dispose');
      expect(unobserveIndex, greaterThanOrEqualTo(0));
      expect(cancelIndex, greaterThan(unobserveIndex));
      expect(disposeIndex, greaterThan(cancelIndex));
    });

    test('释放会话会等待已经进入底层的设置命令完成', () async {
      await session.open(
        'https://example.com/video.mp4',
        kind: PlaybackMediaKind.networkVod,
      );
      final rateGate = Completer<void>();
      engine.rateGate = rateGate;
      final rateOperation = session.setRate(1.5);
      await _flushEvents();
      expect(engine.calls, contains('rate:1.5'));

      final disposeOperation = session.disposeSession();
      await _flushEvents();
      expect(engine.calls, isNot(contains('dispose')));
      rateGate.complete();

      await rateOperation;
      await disposeOperation;
      expect(
        engine.calls.indexOf('dispose'),
        greaterThan(engine.calls.indexOf('rate:1.5')),
      );
    });
  });
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

final class _FakePlaybackEngine implements PlaybackEngine {
  _FakePlaybackEngine()
    : positionStream = _controller<Duration>('position'),
      durationStream = _controller<Duration>('duration'),
      playingStream = _controller<bool>('playing'),
      bufferingStream = _controller<bool>('buffering'),
      completedStream = _controller<bool>('completed'),
      errorStream = _controller<String>('error');

  static final List<String> _pendingCancellationCalls = <String>[];

  static StreamController<T> _controller<T>(String name) =>
      StreamController<T>.broadcast(
        onCancel: () => _pendingCancellationCalls.add('cancel:$name'),
      );

  final List<String> calls = <String>[];
  final List<String> openedUrls = <String>[];
  final List<Map<String, String>> openedHeaders = <Map<String, String>>[];
  final List<Duration?> openedStartAts = <Duration?>[];
  final List<Future<void> Function(String)> cacheListeners =
      <Future<void> Function(String)>[];
  final StreamController<Duration> positionStream;
  final StreamController<Duration> durationStream;
  final StreamController<bool> playingStream;
  final StreamController<bool> bufferingStream;
  final StreamController<bool> completedStream;
  final StreamController<String> errorStream;

  Completer<void>? openGate;
  Completer<void>? playGate;
  Completer<void>? seekGate;
  Completer<void>? rateGate;
  Completer<void>? volumeGate;
  String? failingProperty;
  bool failingObserve = false;
  bool failingSeek = false;
  bool failingPlay = false;
  String? cacheState;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  final bool _buffering = false;
  double _rate = 1.0;
  double _volume = 100.0;

  @override
  VideoController get videoController =>
      throw UnsupportedError('测试不渲染原生 VideoController');

  @override
  Stream<Duration> get positions => positionStream.stream;

  @override
  Stream<Duration> get durations => durationStream.stream;

  @override
  Stream<bool> get playingChanges => playingStream.stream;

  @override
  Stream<bool> get bufferingChanges => bufferingStream.stream;

  @override
  Stream<bool> get completedChanges => completedStream.stream;

  @override
  Stream<String> get errors => errorStream.stream;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  bool get playing => _playing;

  @override
  bool get buffering => _buffering;

  @override
  double get rate => _rate;

  @override
  double get volume => _volume;

  @override
  bool get supportsNativeCacheProperties => true;

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> open(
    String url, {
    required Map<String, String> headers,
    Duration? startAt,
  }) async {
    calls.add('open');
    openedUrls.add(url);
    openedHeaders.add(Map<String, String>.of(headers));
    openedStartAts.add(startAt);
    final gate = openGate;
    openGate = null;
    await gate?.future;
  }

  @override
  Future<void> setProperty(String property, String value) async {
    calls.add('set:$property=$value');
    if (property == failingProperty) {
      throw StateError('property failed');
    }
  }

  @override
  Future<void> observeCacheState(
    Future<void> Function(String value) listener,
  ) async {
    calls.add('observe');
    if (failingObserve) throw StateError('observe failed');
    cacheListeners.add(listener);
  }

  @override
  Future<String?> readCacheState() async =>
      cacheState ?? jsonEncode(<String, Object>{'seekable-ranges': <Object>[]});

  @override
  Future<void> unobserveCacheState() async {
    calls.add('unobserve');
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek:${position.inMilliseconds}');
    final gate = seekGate;
    seekGate = null;
    await gate?.future;
    if (failingSeek) throw StateError('seek failed');
    _position = position;
    positionStream.add(position);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    final gate = playGate;
    playGate = null;
    await gate?.future;
    if (failingPlay) throw StateError('play failed');
    _playing = true;
    playingStream.add(true);
  }

  @override
  Future<void> pause() async {
    _playing = false;
    playingStream.add(false);
  }

  @override
  Future<void> setRate(double rate) async {
    calls.add('rate:$rate');
    final gate = rateGate;
    rateGate = null;
    await gate?.future;
    _rate = rate;
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('volume:$volume');
    final gate = volumeGate;
    volumeGate = null;
    await gate?.future;
    _volume = volume;
  }

  @override
  Future<void> dispose() async {
    calls.addAll(_pendingCancellationCalls);
    _pendingCancellationCalls.clear();
    calls.add('dispose');
  }

  void emitDuration(Duration value) {
    _duration = value;
    durationStream.add(value);
  }

  void emitPosition(Duration value) {
    _position = value;
    positionStream.add(value);
  }

  void emitCompleted(bool value) {
    completedStream.add(value);
  }

  void emitError(String value) {
    errorStream.add(value);
  }

  Future<void> closeStreams() async {
    await positionStream.close();
    await durationStream.close();
    await playingStream.close();
    await bufferingStream.close();
    await completedStream.close();
    await errorStream.close();
  }
}
