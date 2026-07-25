import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';

class DownloadProbeResult {
  const DownloadProbeResult({
    this.durationMs,
    this.isLiveStream = false,
  });

  final int? durationMs;
  final bool isLiveStream;
}

class DownloadProgress {
  const DownloadProgress({
    required this.processedTimeMs,
    required this.downloadedBytes,
    required this.bytesPerSecond,
  });

  final int processedTimeMs;
  final int downloadedBytes;
  final double? bytesPerSecond;
}

double? calculateDownloadBytesPerSecond({
  required int downloadedBytes,
  required Duration elapsed,
}) {
  if (downloadedBytes <= 0 || elapsed.inMicroseconds <= 0) {
    return null;
  }
  return downloadedBytes *
      Duration.microsecondsPerSecond /
      elapsed.inMicroseconds;
}

class DownloadEngineException implements Exception {
  const DownloadEngineException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class VideoDownloadEngine {
  Future<DownloadProbeResult> probe({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
  });

  Future<void> download({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
    required String outputPath,
    required void Function(DownloadProgress progress) onProgress,
  });

  Future<void> verify({
    required String taskId,
    required String filePath,
  });

  Future<void> cancel(String taskId);
}

class FfmpegDownloadEngine implements VideoDownloadEngine {
  static const _userAgent =
      'Mozilla/5.0 (Selene Video Downloader; Flutter) AppleWebKit/537.36';

  final Map<String, int> _activeSessions = <String, int>{};
  final Map<String, Completer<int?>> _startingSessions =
      <String, Completer<int?>>{};

  @override
  Future<DownloadProbeResult> probe({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
  }) async {
    _validateMediaUrl(mediaUrl);
    final arguments = <String>[
      '-v',
      'error',
      '-hide_banner',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      '-show_chapters',
      '-rw_timeout',
      '15000000',
      ..._inputHeaderArguments(headers),
      '-user_agent',
      _userAgent,
      '-i',
      mediaUrl,
    ];
    final completedSession = await _executeMediaInformationSession(
      taskId: taskId,
      arguments: arguments,
      timeoutMs: 20000,
      creationError: '媒体信息会话创建失败',
      failureError: '无法读取媒体信息',
      cancellationError: '媒体信息读取已取消',
    );
    final information = completedSession.getMediaInformation();
    if (information == null) {
      throw const DownloadEngineException('无法读取媒体信息');
    }
    final durationSeconds = double.tryParse(information.getDuration() ?? '');
    final durationMs = durationSeconds == null || durationSeconds <= 0
        ? null
        : (durationSeconds * 1000).round();
    final format = information.getFormat()?.toLowerCase() ?? '';
    return DownloadProbeResult(
      durationMs: durationMs,
      isLiveStream: durationMs == null &&
          (format.contains('hls') || format.contains('applehttp')),
    );
  }

  @override
  Future<void> download({
    required String taskId,
    required String mediaUrl,
    required Map<String, String> headers,
    required String outputPath,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    _validateMediaUrl(mediaUrl);
    final completion = Completer<FFmpegSession>();
    final sessionReady = Completer<int?>();
    _startingSessions[taskId] = sessionReady;
    final elapsed = Stopwatch()..start();
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        <String>[
          '-hide_banner',
          '-loglevel',
          'warning',
          '-nostdin',
          '-y',
          '-rw_timeout',
          '15000000',
          '-reconnect',
          '1',
          '-reconnect_streamed',
          '1',
          '-reconnect_delay_max',
          '5',
          ..._inputHeaderArguments(headers),
          '-user_agent',
          _userAgent,
          '-i',
          mediaUrl,
          '-c',
          'copy',
          '-max_muxing_queue_size',
          '2048',
          '-avoid_negative_ts',
          'make_zero',
          '-f',
          'matroska',
          outputPath,
        ],
        (completedSession) {
          if (!completion.isCompleted) {
            completion.complete(completedSession);
          }
        },
        null,
        (statistics) {
          onProgress(
            DownloadProgress(
              processedTimeMs: statistics.getTime(),
              downloadedBytes: statistics.getSize(),
              bytesPerSecond: calculateDownloadBytesPerSecond(
                downloadedBytes: statistics.getSize(),
                elapsed: elapsed.elapsed,
              ),
            ),
          );
        },
      );

      final sessionId = session.getSessionId();
      if (sessionId == null) {
        sessionReady.complete(null);
        throw const DownloadEngineException('下载会话创建失败');
      }
      _activeSessions[taskId] = sessionId;
      sessionReady.complete(sessionId);

      final completedSession = await completion.future;
      final returnCode = await completedSession.getReturnCode();
      if (ReturnCode.isCancel(returnCode)) {
        throw const DownloadEngineException('下载已取消');
      }
      if (!ReturnCode.isSuccess(returnCode)) {
        throw DownloadEngineException(
          returnCode == null
              ? '下载进程异常结束'
              : '下载失败（错误码 ${returnCode.getValue()}）',
        );
      }
    } finally {
      if (!sessionReady.isCompleted) {
        sessionReady.complete(null);
      }
      if (identical(_startingSessions[taskId], sessionReady)) {
        _startingSessions.remove(taskId);
      }
      _activeSessions.remove(taskId);
    }
  }

  @override
  Future<void> verify({
    required String taskId,
    required String filePath,
  }) async {
    final session = await _executeMediaInformationSession(
      taskId: taskId,
      arguments: <String>[
        '-v',
        'error',
        '-hide_banner',
        '-print_format',
        'json',
        '-show_format',
        '-show_streams',
        '-show_chapters',
        '-i',
        filePath,
      ],
      timeoutMs: 15000,
      creationError: '文件校验会话创建失败',
      failureError: '下载文件无法播放',
      cancellationError: '文件校验已取消',
    );
    final information = session.getMediaInformation();
    final hasVideo = information?.getStreams().any(
              (stream) => stream.getType() == 'video',
            ) ??
        false;
    if (!hasVideo) {
      throw const DownloadEngineException('下载文件无法播放');
    }
  }

  Future<MediaInformationSession> _executeMediaInformationSession({
    required String taskId,
    required List<String> arguments,
    required int timeoutMs,
    required String creationError,
    required String failureError,
    required String cancellationError,
  }) async {
    final completion = Completer<MediaInformationSession>();
    final sessionReady = Completer<int?>();
    _startingSessions[taskId] = sessionReady;
    try {
      final session =
          await FFprobeKit.getMediaInformationFromCommandArgumentsAsync(
        arguments,
        (completedSession) {
          if (!completion.isCompleted) {
            completion.complete(completedSession);
          }
        },
        null,
        timeoutMs,
      );
      final sessionId = session.getSessionId();
      if (sessionId == null) {
        sessionReady.complete(null);
        throw DownloadEngineException(creationError);
      }
      _activeSessions[taskId] = sessionId;
      sessionReady.complete(sessionId);

      final completedSession = await completion.future;
      final returnCode = await completedSession.getReturnCode();
      if (ReturnCode.isCancel(returnCode)) {
        throw DownloadEngineException(cancellationError);
      }
      if (!ReturnCode.isSuccess(returnCode)) {
        throw DownloadEngineException(failureError);
      }
      return completedSession;
    } finally {
      if (!sessionReady.isCompleted) {
        sessionReady.complete(null);
      }
      if (identical(_startingSessions[taskId], sessionReady)) {
        _startingSessions.remove(taskId);
      }
      _activeSessions.remove(taskId);
    }
  }

  @override
  Future<void> cancel(String taskId) async {
    final sessionId = _activeSessions[taskId];
    if (sessionId != null) {
      await FFmpegKit.cancel(sessionId);
      return;
    }
    final startingSession = _startingSessions[taskId];
    if (startingSession == null) {
      return;
    }
    final startingSessionId = await startingSession.future;
    if (startingSessionId != null) {
      await FFmpegKit.cancel(startingSessionId);
    }
  }

  static List<String> _inputHeaderArguments(Map<String, String> headers) {
    if (headers.isEmpty) {
      return const <String>[];
    }
    final lines = <String>[];
    for (final entry in headers.entries) {
      if (!_isSafeHeaderName(entry.key) || !_isSafeHeaderValue(entry.value)) {
        throw const DownloadEngineException('媒体请求头格式不合法');
      }
      lines.add('${entry.key}: ${entry.value}');
    }
    return <String>['-headers', '${lines.join('\r\n')}\r\n'];
  }

  static bool _isSafeHeaderName(String value) => RegExp(
        r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$",
      ).hasMatch(value);

  static bool _isSafeHeaderValue(String value) =>
      !value.codeUnits.any((code) => code < 0x20 && code != 0x09) &&
      !value.contains(String.fromCharCode(0x7f));

  static void _validateMediaUrl(String mediaUrl) {
    final uri = Uri.tryParse(mediaUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const DownloadEngineException('仅支持 HTTP 或 HTTPS 视频地址');
    }
  }
}
