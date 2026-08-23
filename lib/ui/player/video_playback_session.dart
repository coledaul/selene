import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../utils/app_logger.dart';
import '../../utils/result.dart';
import 'playback_engine.dart';
import 'playback_models.dart';

export 'playback_engine.dart';
export 'playback_models.dart';

/// 单媒体播放会话，统一拥有播放器、缓存策略与异步状态。
///
/// [VideoPlayerWidget] 在换源和重试时会重建本会话，使每个媒体都拥有独立的真实首帧信号。
final class VideoPlaybackSession extends ChangeNotifier {
  VideoPlaybackSession({PlaybackEngine? engine, PlaybackDiagnostic? diagnostic})
    : _engine = engine ?? MediaKitPlaybackEngine(),
      _diagnostic = diagnostic ?? _defaultDiagnostic {
    _state = VideoPlaybackState(rate: _engine.rate, volume: _engine.volume);
  }

  final PlaybackEngine _engine;
  final PlaybackDiagnostic _diagnostic;
  final List<VoidCallback> _progressListeners = <VoidCallback>[];
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  late VideoPlaybackState _state;
  Future<void> _operationQueue = Future<void>.value();
  Future<void> _rateCommandQueue = Future<void>.value();
  Future<void> _volumeCommandQueue = Future<void>.value();
  int _generation = 0;
  int _openedGeneration = 0;
  int _rateCommandGeneration = 0;
  int _volumeCommandGeneration = 0;
  bool _controllerFirstFrameWaitStarted = false;
  bool _cacheStateObserved = false;
  bool _cacheStateProbeStarted = false;
  bool _receivedCacheState = false;
  bool _receivedObservedCacheState = false;
  bool _cacheLimitSwitching = false;
  bool _disposed = false;
  bool _notifierDisposed = false;
  Future<void>? _disposeFuture;
  Map<String, String> _currentHeaders = const <String, String>{};
  PlaybackMediaKind _currentKind = PlaybackMediaKind.networkVod;

  VideoPlaybackState get state => _state;
  VideoController get videoController => _engine.videoController;
  double get playbackRate => _state.rate;
  double get volume => _state.volume;

  Future<void> open(
    String url, {
    required PlaybackMediaKind kind,
    Duration? startAt,
    Map<String, String>? headers,
  }) {
    if (_disposed) return Future<void>.value();
    final effectiveHeaders = headers == null
        ? _currentHeaders
        : Map<String, String>.unmodifiable(headers);
    _currentHeaders = effectiveHeaders;
    _currentKind = kind;
    final generation = ++_generation;
    _openedGeneration = 0;
    _cacheStateProbeStarted = false;
    _receivedCacheState = false;
    _receivedObservedCacheState = false;
    _publish(
      VideoPlaybackState(
        mediaKind: kind,
        opening: true,
        buffering: true,
        position: startAt ?? Duration.zero,
        rate: _state.rate,
        volume: _state.volume,
      ),
    );

    final previous = _operationQueue.catchError((Object _, StackTrace _) {});
    final operation = previous.then<void>((_) async {
      if (!_isActive(generation)) return;
      await _openSource(
        url,
        kind: kind,
        startAt: startAt,
        headers: effectiveHeaders,
        generation: generation,
      );
    });
    _operationQueue = operation;
    return operation;
  }

  Future<void> _openSource(
    String url, {
    required PlaybackMediaKind kind,
    required Duration? startAt,
    required Map<String, String> headers,
    required int generation,
  }) async {
    await _removeCacheObservation();
    await _cancelSubscriptions();
    if (!_isActive(generation)) return;

    try {
      await _engine.stop();
    } catch (error) {
      _diagnose('播放器旧媒体关闭失败', error);
    }
    if (!_isActive(generation)) return;

    final policy = PlaybackCachePolicy.forMediaKind(kind);
    if (_engine.supportsNativeCacheProperties) {
      for (final property in policy.properties.entries) {
        try {
          await _engine.setProperty(property.key, property.value);
        } catch (error) {
          _diagnose('播放器缓存属性配置失败', error);
          _setWarning(
            generation,
            const AppFailure(
              kind: FailureKind.platform,
              message: '播放器缓存配置不可用，已降级为默认播放策略',
            ),
          );
        }
        if (!_isActive(generation)) return;
      }
    }

    _subscribeToStreams(generation, policy);
    if (kind == PlaybackMediaKind.networkVod &&
        _engine.supportsNativeCacheProperties) {
      try {
        await _engine.observeCacheState(
          (value) => _handleObservedCacheState(value, generation, policy),
        );
        _cacheStateObserved = true;
      } catch (error) {
        _diagnose('播放器缓存状态观察失败', error);
        _setWarning(
          generation,
          const AppFailure(
            kind: FailureKind.platform,
            message: '无法读取缓存范围，播放将继续使用默认状态',
          ),
        );
      }
    }
    if (!_isActive(generation)) return;

    try {
      await _engine.open(url, headers: headers, startAt: startAt);
      if (!_isActive(generation)) return;
      _openedGeneration = generation;
      if (!_controllerFirstFrameWaitStarted) {
        _controllerFirstFrameWaitStarted = true;
        unawaited(_waitForControllerFirstFrame(generation));
      }
      await _rateCommandQueue.catchError((Object _, StackTrace _) {});
      if (!_isActive(generation)) return;
      await _engine.setRate(_state.rate);
    } catch (error) {
      _diagnose('播放器媒体打开失败', error);
      _setFailure(
        generation,
        const AppFailure(kind: FailureKind.platform, message: '视频打开失败，请重试'),
        retryable: true,
        opening: false,
        buffering: false,
      );
    }
  }

  void _subscribeToStreams(int generation, PlaybackCachePolicy policy) {
    _subscriptions
      ..add(
        _engine.positions.listen((position) {
          if (!_isActive(generation)) return;
          _publish(_state.copyWith(position: position));
          for (final listener in List<VoidCallback>.of(_progressListeners)) {
            try {
              listener();
            } catch (error) {
              _diagnose('播放器进度监听器失败', error);
            }
          }
        }),
      )
      ..add(
        _engine.durations.listen((duration) {
          if (!_isActive(generation)) return;
          _publish(_state.copyWith(duration: duration));
          if (duration > Duration.zero &&
              _currentKind == PlaybackMediaKind.networkVod &&
              _engine.supportsNativeCacheProperties) {
            unawaited(_probeCacheState(generation, policy));
          }
        }),
      )
      ..add(
        _engine.playingChanges.listen((playing) {
          if (!_isActive(generation)) return;
          _publish(_state.copyWith(playing: playing));
        }),
      )
      ..add(
        _engine.bufferingChanges.listen((buffering) {
          if (!_isActive(generation)) return;
          _publish(_state.copyWith(buffering: buffering));
        }),
      )
      ..add(
        _engine.completedChanges.listen((completed) {
          if (!_isActive(generation)) return;
          _publish(
            _state.copyWith(
              completed: completed,
              playing: completed ? false : _state.playing,
            ),
          );
        }),
      )
      ..add(
        _engine.errors.listen((_) {
          if (!_isActive(generation)) return;
          _diagnose('播放器错误流事件', const _PlaybackStreamError());
          _setFailure(
            generation,
            const AppFailure(
              kind: FailureKind.platform,
              message: '视频播放发生错误，请重试',
            ),
            retryable: true,
            opening: false,
            buffering: false,
          );
        }),
      );
  }

  Future<void> _waitForControllerFirstFrame(int generation) async {
    try {
      await _engine.waitUntilFirstFrameRendered();
      if (!_isActive(generation) || _openedGeneration != generation) return;
      _publish(
        _state.copyWith(
          ready: true,
          opening: false,
          buffering: _engine.buffering,
        ),
      );
    } catch (error) {
      _diagnose('播放器首帧状态读取失败', error);
    }
  }

  Future<void> _probeCacheState(
    int generation,
    PlaybackCachePolicy policy,
  ) async {
    if (_cacheStateProbeStarted || _receivedCacheState) return;
    _cacheStateProbeStarted = true;
    try {
      final value = await _engine.readCacheState();
      if (!_isActive(generation) || _receivedCacheState) return;
      if (value == null) {
        _diagnose('播放器缓存状态回读失败', const _EmptyCacheState());
        _setWarning(
          generation,
          const AppFailure(
            kind: FailureKind.platform,
            message: '无法确认缓存范围，播放将继续使用默认状态',
          ),
        );
        return;
      }
      await _handleCacheState(value, generation, policy);
      if (_isActive(generation) &&
          !_receivedObservedCacheState &&
          _state.warning == null) {
        _diagnose('播放器缓存状态持续观察未确认', const _EmptyCacheState());
        _setWarning(
          generation,
          const AppFailure(
            kind: FailureKind.platform,
            message: '无法确认缓存范围持续更新，播放将继续使用当前快照',
          ),
        );
      }
    } catch (error) {
      _diagnose('播放器缓存状态回读失败', error);
      _setWarning(
        generation,
        const AppFailure(
          kind: FailureKind.platform,
          message: '无法确认缓存范围，播放将继续使用默认状态',
        ),
      );
    }
  }

  Future<void> _handleObservedCacheState(
    String value,
    int generation,
    PlaybackCachePolicy policy,
  ) async {
    if (!_isActive(generation)) return;
    _receivedObservedCacheState = true;
    final warning = _state.warning;
    if (warning?.message == '无法确认缓存范围持续更新，播放将继续使用当前快照') {
      _publish(_state.copyWith(warning: null));
    }
    await _handleCacheState(value, generation, policy);
  }

  Future<void> _handleCacheState(
    String value,
    int generation,
    PlaybackCachePolicy policy,
  ) async {
    if (!_isActive(generation)) return;
    if (_state.duration <= Duration.zero) return;
    final snapshot = PlaybackCacheSnapshot.tryParse(
      value,
      duration: _state.duration,
    );
    if (snapshot == null || !_isActive(generation)) {
      if (snapshot == null) {
        _diagnose('播放器缓存状态解析失败', const FormatException());
      }
      return;
    }
    _receivedCacheState = true;

    _publish(
      _state.copyWith(
        cachedRanges: snapshot.ranges,
        temporaryCacheBytes: snapshot.fileCacheBytes,
      ),
    );

    final limit = policy.maxDiskCacheBytes;
    if (limit == null ||
        snapshot.fileCacheBytes < limit ||
        _state.cacheLimitReached ||
        _cacheLimitSwitching) {
      return;
    }

    _cacheLimitSwitching = true;
    try {
      await _engine.setProperty('cache-on-disk', 'no');
      if (!_isActive(generation)) return;
      _publish(
        _state.copyWith(
          cacheLimitReached: true,
          warning: const AppFailure(
            kind: FailureKind.storage,
            message: '临时缓存已达到 1 GB 上限，后续内容将使用滚动缓冲',
          ),
        ),
      );
    } catch (error) {
      _diagnose('播放器磁盘缓存停写失败', error);
      if (_isActive(generation)) {
        try {
          await _engine.stop();
        } catch (stopError) {
          _diagnose('播放器存储保护停止失败', stopError);
        }
        _setFailure(
          generation,
          const AppFailure(
            kind: FailureKind.storage,
            message: '无法限制临时缓存大小，已停止播放以保护存储空间',
          ),
          opening: false,
          buffering: false,
        );
      }
    } finally {
      _cacheLimitSwitching = false;
    }
  }

  Future<void> seek(Duration position) async {
    await _operationQueue.catchError((Object _, StackTrace _) {});
    if (_disposed) return;
    final generation = _generation;
    final target = _clampPosition(position);
    final isLocallySeekable =
        _state.mediaKind == PlaybackMediaKind.localFile ||
        _state.cachedRanges.any((range) => range.contains(target));
    _publish(
      _state.copyWith(
        completed: false,
        buffering: isLocallySeekable ? _state.buffering : true,
        failure: null,
        failureRetryable: false,
      ),
    );
    try {
      await _engine.seek(target);
      if (_isActive(generation)) {
        _publish(_state.copyWith(position: _engine.position));
      }
    } catch (error) {
      _diagnose('播放器跳转失败', error);
      _setFailure(
        generation,
        const AppFailure(kind: FailureKind.platform, message: '跳转失败，请重试'),
        position: _engine.position,
        buffering: _engine.buffering,
      );
    }
  }

  Duration _clampPosition(Duration position) {
    if (position < Duration.zero) return Duration.zero;
    if (_state.duration > Duration.zero && position > _state.duration) {
      return _state.duration;
    }
    return position;
  }

  Future<void> replay() async {
    if (_disposed) return;
    final generation = _generation;
    await seek(Duration.zero);
    if (!_isActive(generation) || _state.failure != null) return;
    await _runSourceCommand(
      generation: generation,
      operation: _engine.play,
      diagnosticEvent: '播放器重播失败',
      failure: const AppFailure(
        kind: FailureKind.platform,
        message: '重新播放失败，请重试',
      ),
      onSuccess: () {
        _publish(
          _state.copyWith(
            position: _engine.position,
            playing: true,
            completed: false,
            failure: null,
            failureRetryable: false,
          ),
        );
      },
    );
  }

  Future<void> play() async {
    if (_state.completed) return replay();
    if (_disposed) return;
    await _runSourceCommand(
      generation: _generation,
      operation: _engine.play,
      diagnosticEvent: '播放器继续播放失败',
      failure: const AppFailure(kind: FailureKind.platform, message: '继续播放失败'),
    );
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _runSourceCommand(
      generation: _generation,
      operation: _engine.pause,
      diagnosticEvent: '播放器暂停失败',
      failure: const AppFailure(kind: FailureKind.platform, message: '暂停播放失败'),
    );
  }

  Future<void> setRate(double rate) {
    if (_disposed) return Future<void>.value();
    final commandGeneration = ++_rateCommandGeneration;
    _publish(_state.copyWith(rate: rate));
    final operation = _runLatestSettingCommand(
      previous: _rateCommandQueue,
      isCurrent: () => commandGeneration == _rateCommandGeneration,
      operation: () => _engine.setRate(rate),
      publishActualValue: () => _publish(_state.copyWith(rate: _engine.rate)),
      diagnosticEvent: '播放器倍速设置失败',
      failure: const AppFailure(kind: FailureKind.platform, message: '倍速设置失败'),
    );
    _rateCommandQueue = operation;
    return operation;
  }

  Future<void> setVolume(double volume) {
    if (_disposed) return Future<void>.value();
    final commandGeneration = ++_volumeCommandGeneration;
    _publish(_state.copyWith(volume: volume));
    final operation = _runLatestSettingCommand(
      previous: _volumeCommandQueue,
      isCurrent: () => commandGeneration == _volumeCommandGeneration,
      operation: () => _engine.setVolume(volume),
      publishActualValue: () =>
          _publish(_state.copyWith(volume: _engine.volume)),
      diagnosticEvent: '播放器音量设置失败',
      failure: const AppFailure(kind: FailureKind.platform, message: '音量设置失败'),
    );
    _volumeCommandQueue = operation;
    return operation;
  }

  Future<void> _runSourceCommand({
    required int generation,
    required Future<void> Function() operation,
    required String diagnosticEvent,
    required AppFailure failure,
    VoidCallback? onSuccess,
  }) async {
    try {
      await operation();
      if (!_isActive(generation)) return;
      onSuccess?.call();
    } catch (error) {
      _diagnose(diagnosticEvent, error);
      _setFailure(generation, failure);
    }
  }

  Future<void> _runLatestSettingCommand({
    required Future<void> previous,
    required bool Function() isCurrent,
    required Future<void> Function() operation,
    required VoidCallback publishActualValue,
    required String diagnosticEvent,
    required AppFailure failure,
  }) async {
    await previous.catchError((Object _, StackTrace _) {});
    if (_disposed || !isCurrent()) return;
    try {
      await operation();
      if (_disposed || !isCurrent()) return;
      publishActualValue();
    } catch (error) {
      _diagnose(diagnosticEvent, error);
      if (_disposed || !isCurrent()) return;
      publishActualValue();
      _setFailure(_generation, failure);
    }
  }

  void clearProblem() {
    if (_disposed) return;
    _publish(
      _state.copyWith(failure: null, failureRetryable: false, warning: null),
    );
  }

  void addProgressListener(VoidCallback listener) {
    if (!_progressListeners.contains(listener)) {
      _progressListeners.add(listener);
    }
  }

  void removeProgressListener(VoidCallback listener) {
    _progressListeners.remove(listener);
  }

  Future<void> _removeCacheObservation() async {
    if (!_cacheStateObserved) return;
    _cacheStateObserved = false;
    try {
      await _engine.unobserveCacheState();
    } catch (error) {
      _diagnose('播放器缓存状态取消观察失败', error);
    }
  }

  Future<void> _cancelSubscriptions() async {
    final subscriptions = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      try {
        await subscription.cancel();
      } catch (error) {
        _diagnose('播放器流订阅取消失败', error);
      }
    }
  }

  void _setFailure(
    int generation,
    AppFailure failure, {
    bool retryable = false,
    bool? opening,
    bool? buffering,
    Duration? position,
  }) {
    if (!_isActive(generation)) return;
    _publish(
      _state.copyWith(
        failure: failure,
        failureRetryable: retryable,
        opening: opening,
        buffering: buffering,
        position: position,
      ),
    );
  }

  void _setWarning(int generation, AppFailure warning) {
    if (!_isActive(generation)) return;
    _publish(_state.copyWith(warning: warning));
  }

  void _publish(VideoPlaybackState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  bool _isActive(int generation) => !_disposed && generation == _generation;

  void _diagnose(String event, Object error) {
    _diagnostic(event, error);
  }

  static void _defaultDiagnostic(String event, Object error) {
    AppLogger.debug('$event：${error.runtimeType}');
  }

  Future<void> disposeSession() => _disposeFuture ??= _disposeResources();

  Future<void> _disposeResources() async {
    _disposed = true;
    _generation++;
    await _operationQueue.catchError((Object _, StackTrace _) {});
    await _rateCommandQueue.catchError((Object _, StackTrace _) {});
    await _volumeCommandQueue.catchError((Object _, StackTrace _) {});
    await _removeCacheObservation();
    await _cancelSubscriptions();
    _progressListeners.clear();
    try {
      await _engine.dispose();
    } catch (error) {
      _diagnose('播放器资源释放失败', error);
    } finally {
      _disposeNotifier();
    }
  }

  void _disposeNotifier() {
    if (_notifierDisposed) return;
    _notifierDisposed = true;
    super.dispose();
  }

  @override
  void dispose() {
    unawaited(disposeSession());
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
  }
}

final class _PlaybackStreamError implements Exception {
  const _PlaybackStreamError();
}

final class _EmptyCacheState implements Exception {
  const _EmptyCacheState();
}
