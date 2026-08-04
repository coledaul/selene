import 'dart:convert';

import '../../utils/result.dart';

enum PlaybackMediaKind { networkVod, live, localFile }

/// 一次播放器打开请求解析后的地址与缓存策略类型。
final class PlaybackMediaSource {
  const PlaybackMediaSource({required this.url, required this.kind});

  final String url;
  final PlaybackMediaKind kind;
}

final class PlaybackBufferedRange {
  const PlaybackBufferedRange({required this.start, required this.end});

  final Duration start;
  final Duration end;

  bool contains(Duration position) => position >= start && position <= end;

  @override
  bool operator ==(Object other) =>
      other is PlaybackBufferedRange &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

final class PlaybackCachePolicy {
  const PlaybackCachePolicy({required this.properties, this.maxDiskCacheBytes});

  static const int defaultMaxDiskCacheBytes = 1024 * 1024 * 1024;

  final Map<String, String> properties;
  final int? maxDiskCacheBytes;

  factory PlaybackCachePolicy.forMediaKind(PlaybackMediaKind kind) =>
      switch (kind) {
        PlaybackMediaKind.networkVod => const PlaybackCachePolicy(
          properties: <String, String>{
            'cache': 'yes',
            'cache-on-disk': 'yes',
            'cache-secs': '180',
            'demuxer-max-bytes': '32MiB',
            'demuxer-max-back-bytes': '128MiB',
            'demuxer-seekable-cache': 'yes',
            'demuxer-donate-buffer': 'yes',
            'cache-pause': 'yes',
            'cache-pause-initial': 'yes',
            'cache-pause-wait': '2',
            'demuxer-cache-unlink-files': 'immediate',
          },
          maxDiskCacheBytes: defaultMaxDiskCacheBytes,
        ),
        PlaybackMediaKind.live => const PlaybackCachePolicy(
          properties: <String, String>{
            'cache': 'yes',
            'cache-on-disk': 'no',
            'cache-secs': '10',
            'demuxer-max-bytes': '16MiB',
            'demuxer-max-back-bytes': '0',
            'demuxer-seekable-cache': 'no',
            'demuxer-donate-buffer': 'no',
            'cache-pause': 'yes',
            'cache-pause-initial': 'no',
            'cache-pause-wait': '1',
            'demuxer-cache-unlink-files': 'immediate',
          },
        ),
        PlaybackMediaKind.localFile => const PlaybackCachePolicy(
          properties: <String, String>{
            'cache': 'no',
            'cache-on-disk': 'no',
            'cache-secs': '0',
            'demuxer-max-bytes': '32MiB',
            'demuxer-max-back-bytes': '0',
            'demuxer-seekable-cache': 'no',
            'demuxer-donate-buffer': 'no',
            'cache-pause': 'no',
            'cache-pause-initial': 'no',
            'cache-pause-wait': '1',
            'demuxer-cache-unlink-files': 'immediate',
          },
        ),
      };
}

final class PlaybackCacheSnapshot {
  const PlaybackCacheSnapshot({
    required this.ranges,
    required this.beginningOfFileCached,
    required this.endOfFileCached,
    required this.fileCacheBytes,
    required this.readerPosition,
    required this.cacheEnd,
    required this.rawInputRate,
  });

  final List<PlaybackBufferedRange> ranges;
  final bool beginningOfFileCached;
  final bool endOfFileCached;
  final int fileCacheBytes;
  final Duration? readerPosition;
  final Duration? cacheEnd;
  final int? rawInputRate;

  static PlaybackCacheSnapshot? tryParse(
    String value, {
    required Duration duration,
  }) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final rawRanges = decoded['seekable-ranges'];
      if (rawRanges is! List<dynamic>) return null;

      final ranges = <PlaybackBufferedRange>[];
      for (final rawRange in rawRanges) {
        if (rawRange is! Map<String, dynamic>) return null;
        final start = _finiteDouble(rawRange['start']);
        final end = _finiteDouble(rawRange['end']);
        if (start == null || end == null) return null;
        final clampedStart = _clampSeconds(start, duration);
        final clampedEnd = _clampSeconds(end, duration);
        if (clampedEnd <= clampedStart) continue;
        ranges.add(PlaybackBufferedRange(start: clampedStart, end: clampedEnd));
      }

      ranges.sort((left, right) => left.start.compareTo(right.start));
      final merged = <PlaybackBufferedRange>[];
      const adjacency = Duration(milliseconds: 250);
      for (final range in ranges) {
        if (merged.isEmpty) {
          merged.add(range);
          continue;
        }
        final previous = merged.last;
        if (range.start <= previous.end + adjacency) {
          merged[merged.length - 1] = PlaybackBufferedRange(
            start: previous.start,
            end: range.end > previous.end ? range.end : previous.end,
          );
        } else {
          merged.add(range);
        }
      }

      return PlaybackCacheSnapshot(
        ranges: List<PlaybackBufferedRange>.unmodifiable(merged),
        beginningOfFileCached: _optionalBool(decoded, 'bof-cached') ?? false,
        endOfFileCached: _optionalBool(decoded, 'eof-cached') ?? false,
        fileCacheBytes:
            _optionalNonNegativeInt(decoded, 'file-cache-bytes') ?? 0,
        readerPosition: _optionalDuration(decoded, 'reader-pts', duration),
        cacheEnd: _optionalDuration(decoded, 'cache-end', duration),
        rawInputRate: _optionalNonNegativeInt(decoded, 'raw-input-rate'),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static double? _finiteDouble(Object? value) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }

  static Duration _clampSeconds(double seconds, Duration duration) {
    final maximum = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final clamped = seconds.clamp(0.0, maximum);
    return Duration(
      microseconds: (clamped * Duration.microsecondsPerSecond).round(),
    );
  }

  static bool? _optionalBool(Map<String, dynamic> value, String key) {
    final raw = value[key];
    if (raw == null) return null;
    if (raw is! bool) throw const FormatException('invalid boolean');
    return raw;
  }

  static int? _optionalNonNegativeInt(Map<String, dynamic> value, String key) {
    final raw = value[key];
    if (raw == null) return null;
    if (raw is! num || !raw.isFinite) {
      throw const FormatException('invalid integer');
    }
    return raw.toInt().clamp(0, 0x7FFFFFFFFFFFFFFF);
  }

  static Duration? _optionalDuration(
    Map<String, dynamic> value,
    String key,
    Duration duration,
  ) {
    final raw = value[key];
    if (raw == null) return null;
    final seconds = _finiteDouble(raw);
    if (seconds == null) throw const FormatException('invalid duration');
    return _clampSeconds(seconds, duration);
  }
}

const Object _unchangedProblem = Object();

final class VideoPlaybackState {
  const VideoPlaybackState({
    this.mediaKind = PlaybackMediaKind.networkVod,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.buffering = false,
    this.opening = false,
    this.completed = false,
    this.ready = false,
    this.cachedRanges = const <PlaybackBufferedRange>[],
    this.temporaryCacheBytes = 0,
    this.cacheLimitReached = false,
    this.rate = 1.0,
    this.volume = 100.0,
    this.failure,
    this.failureRetryable = false,
    this.warning,
  });

  final PlaybackMediaKind mediaKind;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool buffering;
  final bool opening;
  final bool completed;
  final bool ready;
  final List<PlaybackBufferedRange> cachedRanges;
  final int temporaryCacheBytes;
  final bool cacheLimitReached;
  final double rate;
  final double volume;
  final AppFailure? failure;
  final bool failureRetryable;
  final AppFailure? warning;

  VideoPlaybackState copyWith({
    PlaybackMediaKind? mediaKind,
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? buffering,
    bool? opening,
    bool? completed,
    bool? ready,
    List<PlaybackBufferedRange>? cachedRanges,
    int? temporaryCacheBytes,
    bool? cacheLimitReached,
    double? rate,
    double? volume,
    Object? failure = _unchangedProblem,
    bool? failureRetryable,
    Object? warning = _unchangedProblem,
  }) => VideoPlaybackState(
    mediaKind: mediaKind ?? this.mediaKind,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    buffering: buffering ?? this.buffering,
    opening: opening ?? this.opening,
    completed: completed ?? this.completed,
    ready: ready ?? this.ready,
    cachedRanges: List<PlaybackBufferedRange>.unmodifiable(
      cachedRanges ?? this.cachedRanges,
    ),
    temporaryCacheBytes: temporaryCacheBytes ?? this.temporaryCacheBytes,
    cacheLimitReached: cacheLimitReached ?? this.cacheLimitReached,
    rate: rate ?? this.rate,
    volume: volume ?? this.volume,
    failure: identical(failure, _unchangedProblem)
        ? this.failure
        : failure as AppFailure?,
    failureRetryable: failureRetryable ?? this.failureRetryable,
    warning: identical(warning, _unchangedProblem)
        ? this.warning
        : warning as AppFailure?,
  );
}
