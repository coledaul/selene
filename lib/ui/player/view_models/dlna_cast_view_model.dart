import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/dlna_device_repository.dart';
import '../../../domain/models/dlna_device.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';

const Object _unchangedFailure = Object();

/// 页面级 DLNA 播放状态，只包含 UI 可消费的领域数据。
@immutable
final class DlnaPlaybackState {
  const DlnaPlaybackState({
    this.deviceId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.completed = false,
    this.failure,
  });

  final String? deviceId;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool loading;
  final bool completed;
  final AppFailure? failure;

  DlnaPlaybackState copyWith({
    String? deviceId,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
    bool? completed,
    Object? failure = _unchangedFailure,
  }) => DlnaPlaybackState(
    deviceId: deviceId ?? this.deviceId,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    completed: completed ?? this.completed,
    failure: identical(failure, _unchangedFailure)
        ? this.failure
        : failure as AppFailure?,
  );
}

/// 页面级 DLNA 扫描、连接、远程播放和最近设备状态边界。
final class DlnaCastViewModel extends ViewModel {
  DlnaCastViewModel({
    required DlnaDeviceRepository repository,
    Duration playbackPollInterval = const Duration(milliseconds: 300),
  }) : _repository = repository,
       _playbackPollInterval = playbackPollInterval;

  final DlnaDeviceRepository _repository;
  final Duration _playbackPollInterval;
  StreamSubscription<Map<String, DiscoveredDlnaDevice>>? _devicesSubscription;
  Timer? _scanTimer;
  Timer? _playbackTimer;
  Map<String, DiscoveredDlnaDevice> _devices =
      const <String, DiscoveredDlnaDevice>{};
  RecentDlnaDevice? _recentDevice;
  DiscoveredDlnaDevice? _playbackDevice;
  DlnaPlaybackState _playbackState = const DlnaPlaybackState();
  Duration _resumePosition = Duration.zero;
  bool _scanning = false;
  int? _pollingGeneration;
  int _activePlaybackCommands = 0;
  String _scanStatus = '准备扫描设备...';
  int _scanGeneration = 0;
  int _preferenceGeneration = 0;
  int _playbackGeneration = 0;
  int _commandGeneration = 0;

  Map<String, DiscoveredDlnaDevice> get devices => _devices;
  RecentDlnaDevice? get recentDevice => _recentDevice;
  DlnaPlaybackState get playbackState => _playbackState;
  bool get scanning => _scanning;
  String get scanStatus => _scanStatus;

  Future<Result<void>> loadRecentDevice() async {
    final generation = ++_preferenceGeneration;
    final result = await _repository.loadRecent();
    if (!isActive || generation != _preferenceGeneration) {
      return _cancelled();
    }
    if (result.isFailure) {
      return FailureResult<void>(result.failureOrNull!);
    }
    final next = result.valueOrNull;
    if (_recentDevice != next) {
      _recentDevice = next;
      notifyIfActive();
    }
    return const Success<void>(null);
  }

  Future<Result<void>> rememberDevice(RecentDlnaDevice device) async {
    final generation = ++_preferenceGeneration;
    final result = await _repository.saveRecent(device);
    if (!isActive || generation != _preferenceGeneration) {
      return _cancelled();
    }
    if (result.isFailure) return result;
    if (_recentDevice != device) {
      _recentDevice = device;
      notifyIfActive();
    }
    return const Success<void>(null);
  }

  Future<Result<void>> startScanning() async {
    final generation = ++_scanGeneration;
    _scanTimer?.cancel();
    await _devicesSubscription?.cancel();
    if (!isActive || generation != _scanGeneration) return _cancelled();

    _devices = const <String, DiscoveredDlnaDevice>{};
    _scanning = true;
    _scanStatus = '正在扫描DLNA设备...';
    notifyIfActive();
    _devicesSubscription = _repository.devices.listen(
      (devices) {
        if (!isActive || generation != _scanGeneration) return;
        _devices = Map<String, DiscoveredDlnaDevice>.unmodifiable(devices);
        _scanStatus = '发现 ${_devices.length} 个设备';
        notifyIfActive();
      },
      onError: (Object _, StackTrace _) {
        if (!isActive || generation != _scanGeneration) return;
        _scanning = false;
        _scanStatus = '扫描失败，请检查网络后重试';
        notifyIfActive();
      },
    );

    final result = await _repository.startDiscovery();
    if (!isActive || generation != _scanGeneration) return _cancelled();
    if (result.isFailure) {
      _scanning = false;
      _scanStatus = result.failureOrNull?.message ?? '扫描失败，请检查网络后重试';
      notifyIfActive();
      return result;
    }

    _scanTimer = Timer(const Duration(seconds: 10), () {
      if (!isActive || generation != _scanGeneration) return;
      _scanning = false;
      _scanStatus = '扫描完成，发现 ${_devices.length} 个设备';
      notifyIfActive();
    });
    return const Success<void>(null);
  }

  Future<Result<void>> stopScanning() async {
    _scanGeneration++;
    _scanTimer?.cancel();
    _scanTimer = null;
    await _devicesSubscription?.cancel();
    _devicesSubscription = null;
    return _repository.stopDiscovery();
  }

  Future<Result<void>> refreshScanning() async {
    await stopScanning();
    if (!isActive) return _cancelled();
    _devices = const <String, DiscoveredDlnaDevice>{};
    notifyIfActive();
    return startScanning();
  }

  Future<Result<void>> connect(
    DiscoveredDlnaDevice device, {
    required String mediaUrl,
    required String title,
  }) => _repository.connect(device, mediaUrl: mediaUrl, title: title);

  Future<Result<void>> stopPlayback(DiscoveredDlnaDevice device) =>
      _repository.stopPlayback(device);

  void startPlaybackMonitoring(
    DiscoveredDlnaDevice device, {
    Duration? resumePosition,
  }) {
    final generation = ++_playbackGeneration;
    _commandGeneration++;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackDevice = device;
    _resumePosition = resumePosition ?? Duration.zero;
    _playbackState = DlnaPlaybackState(deviceId: device.id, loading: true);
    notifyIfActive();
    unawaited(_pollPlaybackStatus(generation));
  }

  void stopPlaybackMonitoring() {
    _resetPlaybackMonitoring(notify: true);
  }

  void _resetPlaybackMonitoring({required bool notify}) {
    _playbackGeneration++;
    _commandGeneration++;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackDevice = null;
    _resumePosition = Duration.zero;
    _playbackState = const DlnaPlaybackState();
    if (notify) notifyIfActive();
  }

  Future<Result<void>> togglePlayback() {
    final device = _playbackDevice;
    if (device == null) return Future<Result<void>>.value(_cancelled());
    final shouldPause = _playbackState.playing;
    return _runPlaybackCommand(
      device,
      () => shouldPause ? _repository.pause(device) : _repository.play(device),
      onSuccess: () {
        _playbackState = _playbackState.copyWith(
          playing: !shouldPause,
          failure: null,
        );
      },
    );
  }

  Future<Result<void>> seekPlayback(Duration position) {
    final device = _playbackDevice;
    if (device == null) return Future<Result<void>>.value(_cancelled());
    return _runPlaybackCommand(
      device,
      () => _repository.seek(device, position),
      onSuccess: () {
        _playbackState = _playbackState.copyWith(
          position: position,
          failure: null,
        );
      },
    );
  }

  Future<Result<void>> setPlaybackVolume(double volume) {
    final device = _playbackDevice;
    if (device == null) return Future<Result<void>>.value(_cancelled());
    return _runPlaybackCommand(
      device,
      () => _repository.setVolume(device, volume),
      onSuccess: () {
        _playbackState = _playbackState.copyWith(failure: null);
      },
    );
  }

  Future<Result<void>> _runPlaybackCommand(
    DiscoveredDlnaDevice device,
    Future<Result<void>> Function() command, {
    required VoidCallback onSuccess,
  }) async {
    final playbackGeneration = _playbackGeneration;
    final commandGeneration = ++_commandGeneration;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _activePlaybackCommands++;
    late final Result<void> result;
    try {
      result = await command();
    } finally {
      _activePlaybackCommands--;
    }
    if (!_isActivePlayback(playbackGeneration, device) ||
        commandGeneration != _commandGeneration) {
      _schedulePlaybackPoll(_playbackGeneration, delay: Duration.zero);
      return _cancelled();
    }
    if (result.isFailure) {
      _playbackState = _playbackState.copyWith(failure: result.failureOrNull);
      notifyIfActive();
      _schedulePlaybackPoll(playbackGeneration);
      return result;
    }
    onSuccess();
    notifyIfActive();
    _schedulePlaybackPoll(playbackGeneration, delay: Duration.zero);
    return const Success<void>(null);
  }

  Future<void> _pollPlaybackStatus(int generation) async {
    final device = _playbackDevice;
    if (!_isActivePlayback(generation, device) ||
        _pollingGeneration == generation ||
        _activePlaybackCommands > 0) {
      return;
    }
    final commandGeneration = _commandGeneration;
    _pollingGeneration = generation;
    try {
      final result = await _repository.readPlaybackStatus(device!);
      if (!_isActivePlayback(generation, device) ||
          commandGeneration != _commandGeneration) {
        return;
      }
      if (result.isFailure) {
        _playbackState = _playbackState.copyWith(failure: result.failureOrNull);
        notifyIfActive();
        return;
      }

      final snapshot = result.valueOrNull!;
      AppFailure? resumeFailure;
      var effectivePosition = snapshot.position;
      if (_playbackState.loading &&
          snapshot.duration > Duration.zero &&
          snapshot.playing &&
          _resumePosition > Duration.zero) {
        final target = _resumePosition;
        _resumePosition = Duration.zero;
        final seekResult = await _repository.seek(device, target);
        if (!_isActivePlayback(generation, device) ||
            commandGeneration != _commandGeneration) {
          return;
        }
        resumeFailure = seekResult.failureOrNull;
        if (seekResult.isSuccess) effectivePosition = target;
      }

      final ready = snapshot.duration > Duration.zero && snapshot.playing;
      final completed =
          ready &&
          effectivePosition >= snapshot.duration - const Duration(seconds: 1);
      final firstCompletion = completed && !_playbackState.completed;
      var playing = snapshot.playing;
      var failure = resumeFailure;
      if (firstCompletion) {
        final pauseResult = await _repository.pause(device);
        if (!_isActivePlayback(generation, device) ||
            commandGeneration != _commandGeneration) {
          return;
        }
        playing = pauseResult.isFailure ? snapshot.playing : false;
        failure = pauseResult.failureOrNull ?? resumeFailure;
      }
      _playbackState = DlnaPlaybackState(
        deviceId: device.id,
        position: effectivePosition,
        duration: snapshot.duration,
        playing: playing,
        loading: _playbackState.loading && !ready,
        completed: completed,
        failure: failure,
      );
      notifyIfActive();
    } finally {
      if (_pollingGeneration == generation) _pollingGeneration = null;
      if (_isActivePlayback(generation, device)) {
        _schedulePlaybackPoll(generation);
      }
    }
  }

  void _schedulePlaybackPoll(int generation, {Duration? delay}) {
    if (!_isActivePlayback(generation, _playbackDevice) ||
        _activePlaybackCommands > 0) {
      return;
    }
    _playbackTimer?.cancel();
    _playbackTimer = Timer(delay ?? _playbackPollInterval, () {
      unawaited(_pollPlaybackStatus(generation));
    });
  }

  bool _isActivePlayback(int generation, DiscoveredDlnaDevice? device) =>
      isActive &&
      device != null &&
      generation == _playbackGeneration &&
      identical(device, _playbackDevice);

  FailureResult<void> _cancelled() => const FailureResult<void>(
    AppFailure(kind: FailureKind.cancellation, message: '投屏操作已取消'),
  );

  @override
  void dispose() {
    _scanGeneration++;
    _preferenceGeneration++;
    _resetPlaybackMonitoring(notify: false);
    _scanTimer?.cancel();
    unawaited(_devicesSubscription?.cancel());
    unawaited(_repository.dispose());
    super.dispose();
  }
}
