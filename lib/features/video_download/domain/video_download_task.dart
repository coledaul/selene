import 'dart:convert';

enum VideoDownloadStatus {
  queued,
  probing,
  downloading,
  finalizing,
  completed,
  failed,
  cancelled,
}

class VideoDownloadRequest {
  const VideoDownloadRequest({
    required this.source,
    required this.contentId,
    required this.sourceName,
    required this.title,
    required this.coverUrl,
    required this.episodeIndex,
    required this.episodeTitle,
    required this.totalEpisodes,
    required this.mediaUrl,
    this.headers = const <String, String>{},
  });

  final String source;
  final String contentId;
  final String sourceName;
  final String title;
  final String coverUrl;
  final int episodeIndex;
  final String episodeTitle;
  final int totalEpisodes;
  final String mediaUrl;
  final Map<String, String> headers;

  String get key => buildKey(
        source: source,
        contentId: contentId,
        episodeIndex: episodeIndex,
      );

  static String buildKey({
    required String source,
    required String contentId,
    required int episodeIndex,
  }) =>
      jsonEncode(<Object>[source, contentId, episodeIndex]);
}

class VideoDownloadTask {
  const VideoDownloadTask({
    required this.id,
    required this.key,
    required this.source,
    required this.contentId,
    required this.sourceName,
    required this.title,
    required this.coverUrl,
    required this.episodeIndex,
    required this.episodeTitle,
    required this.totalEpisodes,
    required this.mediaUrl,
    required this.headers,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.durationMs,
    this.bytesPerSecond,
    this.filePath,
    this.errorMessage,
    this.completedAt,
  });

  factory VideoDownloadTask.fromRequest(VideoDownloadRequest request) {
    final now = DateTime.now();
    return VideoDownloadTask(
      id: '${now.microsecondsSinceEpoch}-${request.episodeIndex}',
      key: request.key,
      source: request.source,
      contentId: request.contentId,
      sourceName: request.sourceName,
      title: request.title,
      coverUrl: request.coverUrl,
      episodeIndex: request.episodeIndex,
      episodeTitle: request.episodeTitle,
      totalEpisodes: request.totalEpisodes,
      mediaUrl: request.mediaUrl,
      headers: Map<String, String>.unmodifiable(request.headers),
      status: VideoDownloadStatus.queued,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory VideoDownloadTask.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    return VideoDownloadTask(
      id: json['id'] as String,
      key: json['key'] as String,
      source: json['source'] as String,
      contentId: json['contentId'] as String,
      sourceName: json['sourceName'] as String? ?? '',
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String? ?? '',
      episodeIndex: json['episodeIndex'] as int,
      episodeTitle: json['episodeTitle'] as String,
      totalEpisodes: json['totalEpisodes'] as int,
      mediaUrl: json['mediaUrl'] as String,
      headers: rawHeaders is Map
          ? Map<String, String>.unmodifiable(
              rawHeaders.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
          : const <String, String>{},
      status: VideoDownloadStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => VideoDownloadStatus.failed,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      bytesPerSecond: (json['bytesPerSecond'] as num?)?.toDouble(),
      filePath: json['filePath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }

  final String id;
  final String key;
  final String source;
  final String contentId;
  final String sourceName;
  final String title;
  final String coverUrl;
  final int episodeIndex;
  final String episodeTitle;
  final int totalEpisodes;
  final String mediaUrl;
  final Map<String, String> headers;
  final VideoDownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int? durationMs;
  final double? bytesPerSecond;
  final String? filePath;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get isActive =>
      status == VideoDownloadStatus.probing ||
      status == VideoDownloadStatus.downloading ||
      status == VideoDownloadStatus.finalizing;

  bool get canRetry =>
      status == VideoDownloadStatus.failed ||
      status == VideoDownloadStatus.cancelled;

  VideoDownloadTask copyWith({
    String? sourceName,
    String? title,
    String? coverUrl,
    String? episodeTitle,
    String? mediaUrl,
    Map<String, String>? headers,
    VideoDownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? durationMs,
    bool clearDuration = false,
    double? bytesPerSecond,
    bool clearBytesPerSecond = false,
    String? filePath,
    bool clearFilePath = false,
    String? errorMessage,
    bool clearError = false,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return VideoDownloadTask(
      id: id,
      key: key,
      source: source,
      contentId: contentId,
      sourceName: sourceName ?? this.sourceName,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      episodeIndex: episodeIndex,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      totalEpisodes: totalEpisodes,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      headers: headers ?? this.headers,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      durationMs: clearDuration ? null : (durationMs ?? this.durationMs),
      bytesPerSecond:
          clearBytesPerSecond ? null : (bytesPerSecond ?? this.bytesPerSecond),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'key': key,
        'source': source,
        'contentId': contentId,
        'sourceName': sourceName,
        'title': title,
        'coverUrl': coverUrl,
        'episodeIndex': episodeIndex,
        'episodeTitle': episodeTitle,
        'totalEpisodes': totalEpisodes,
        'mediaUrl': mediaUrl,
        'headers': headers,
        'status': status.name,
        'progress': progress,
        'downloadedBytes': downloadedBytes,
        'durationMs': durationMs,
        'bytesPerSecond': bytesPerSecond,
        'filePath': filePath,
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };
}
