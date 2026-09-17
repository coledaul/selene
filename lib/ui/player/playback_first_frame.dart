import 'dart:async';

/// 单会话首帧等待：输出通知、平台就绪条件、Flutter 帧提交依次确认。
/// 轮询间隔仅限制查询频率；时间经过本身不会使等待成功。
final class PlaybackFirstFrame {
  PlaybackFirstFrame({
    required Future<void> Function() waitForOutput,
    required Future<bool> Function() isOutputReady,
    required Future<void> Function() waitForPresentation,
    Duration timeout = const Duration(seconds: 45),
  }) : _waitForOutput = waitForOutput,
       _isOutputReady = isOutputReady,
       _waitForPresentation = waitForPresentation,
       _timeout = timeout;

  final Future<void> Function() _waitForOutput;
  final Future<bool> Function() _isOutputReady;
  final Future<void> Function() _waitForPresentation;
  final Duration _timeout;
  Completer<void>? _result;
  Completer<void>? _pollDelay;
  Timer? _pollTimer;
  Timer? _deadline;
  bool _disposed = false;

  bool get _finished => _disposed || (_result?.isCompleted ?? false);

  Future<void> wait() {
    if (_disposed) return Future.error(StateError('播放会话已释放'));
    if (_result case final result?) return result.future;
    final result = _result = Completer<void>();
    _deadline = Timer(_timeout, () {
      _finish(TimeoutException('视频首帧等待超时', _timeout));
    });
    unawaited(_run());
    return result.future;
  }

  Future<void> _run() async {
    try {
      await _waitForOutput();
      while (!_finished) {
        final outputReady = await _isOutputReady();
        if (_finished) return;
        if (outputReady) {
          await _waitForPresentation();
          if (_finished) return;
          // 提交期间可能发生 Surface 重建，不能沿用提交前的判断。
          final stillReady = await _isOutputReady();
          if (_finished) return;
          if (stillReady) {
            _finish();
            return;
          }
        }
        final delay = _pollDelay = Completer<void>();
        _pollTimer = Timer(const Duration(milliseconds: 50), delay.complete);
        await delay.future;
        _pollDelay = null;
      }
    } catch (error, stackTrace) {
      _finish(error, stackTrace);
    }
  }

  void _finish([Object? error, StackTrace? stackTrace]) {
    _deadline?.cancel();
    _pollTimer?.cancel();
    final delay = _pollDelay;
    if (delay != null && !delay.isCompleted) delay.complete();
    final result = _result;
    if (result == null || result.isCompleted) return;
    if (error == null) {
      result.complete();
    } else {
      result.completeError(error, stackTrace);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _finish(StateError('播放会话已释放'));
  }
}
