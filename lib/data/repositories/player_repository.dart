import '../../domain/models/douban_movie.dart';
import '../../domain/models/player_models.dart';
import '../../domain/models/search_result.dart';
import '../../utils/result.dart';
import '../services/api_service.dart';
import '../services/content_data_service.dart';
import '../services/m3u8_service.dart';
import '../services/media_url_resolver.dart';

/// 播放器外部数据端口，不参与跨仓库业务编排。
abstract interface class PlayerRepository {
  Future<Result<List<SearchResult>>> searchRemoteSources(PlayerRequest request);
  Future<Result<List<SearchResult>>> fetchRemoteSourceDetail(
    String source,
    String id,
  );
  Future<Result<PreferredPlayerSource>> preferBestSource(
    List<SearchResult> sources,
  );
  Future<Result<Map<String, PlayerSourceSpeed>>> testSources(
    List<SearchResult> sources, {
    void Function(String sourceId, PlayerSourceSpeed speed)? onResult,
  });
  Future<Result<DoubanMovieDetails?>> getDoubanDetails(int doubanId);
  Future<Result<String>> resolveRemotePlaybackUrl(String mediaUrl);
  void dispose();
}

final class DefaultPlayerRepository implements PlayerRepository {
  DefaultPlayerRepository({
    required ApiService apiService,
    M3U8Analyzer? m3u8Service,
    ContentDataService? contentService,
    PlaybackUrlService? playbackUrlService,
  }) : _apiService = apiService,
       _m3u8Service = m3u8Service ?? M3U8Service(),
       _contentService = contentService ?? const DefaultContentDataService(),
       _playbackUrlService =
           playbackUrlService ?? const DefaultPlaybackUrlService();

  final ApiService _apiService;
  final M3U8Analyzer _m3u8Service;
  final ContentDataService _contentService;
  final PlaybackUrlService _playbackUrlService;

  @override
  Future<Result<List<SearchResult>>> searchRemoteSources(
    PlayerRequest request,
  ) => _guard('搜索播放源失败', () async {
    final query = request.searchTitle?.trim().isNotEmpty == true
        ? request.searchTitle!.trim()
        : request.title;
    final results = await _apiService.fetchSourcesData(query);
    final normalizedTitle = request.title.replaceAll(' ', '').toLowerCase();
    return results
        .where((result) {
          final titleMatches =
              result.title.replaceAll(' ', '').toLowerCase() == normalizedTitle;
          final yearMatches =
              request.year == null ||
              result.year.toLowerCase() == request.year!.toLowerCase();
          final typeMatches = switch (request.type) {
            'tv' => result.episodes.length > 1,
            'movie' => result.episodes.length == 1,
            _ => true,
          };
          return titleMatches && yearMatches && typeMatches;
        })
        .toList(growable: false);
  });

  @override
  Future<Result<List<SearchResult>>> fetchRemoteSourceDetail(
    String source,
    String id,
  ) => _guard('获取播放源详情失败', () => _apiService.fetchSourceDetail(source, id));

  @override
  Future<Result<PreferredPlayerSource>> preferBestSource(
    List<SearchResult> sources,
  ) => _guard('播放源优选失败', () async {
    final raw = await _m3u8Service.preferBestSource(sources);
    final best = raw['bestSource'];
    if (best is! SearchResult) {
      throw StateError(raw['error']?.toString() ?? '没有可用的播放源');
    }
    final rawSpeeds = raw['allSourcesSpeed'];
    final speeds = <String, PlayerSourceSpeed>{};
    if (rawSpeeds is Map) {
      for (final entry in rawSpeeds.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          speeds[entry.key.toString()] = _speed(value);
        }
      }
    }
    return PreferredPlayerSource(
      source: best,
      speeds: Map<String, PlayerSourceSpeed>.unmodifiable(speeds),
    );
  });

  @override
  Future<Result<Map<String, PlayerSourceSpeed>>> testSources(
    List<SearchResult> sources, {
    void Function(String sourceId, PlayerSourceSpeed speed)? onResult,
  }) => _guard('播放源测速失败', () async {
    final speeds = <String, PlayerSourceSpeed>{};
    await _m3u8Service.testSourcesWithCallback(sources, (sourceId, raw) {
      final speed = _speed(raw);
      speeds[sourceId] = speed;
      onResult?.call(sourceId, speed);
    }, timeout: const Duration(seconds: 10));
    return Map<String, PlayerSourceSpeed>.unmodifiable(speeds);
  });

  @override
  Future<Result<DoubanMovieDetails?>> getDoubanDetails(int doubanId) =>
      _guard('获取豆瓣详情失败', () async {
        final response = await _contentService.getDoubanDetails('$doubanId');
        if (!response.success) {
          throw StateError(response.message ?? '获取豆瓣详情失败');
        }
        return response.data;
      });

  @override
  Future<Result<String>> resolveRemotePlaybackUrl(String mediaUrl) =>
      _guard('解析播放地址失败', () => _playbackUrlService.resolve(mediaUrl));

  PlayerSourceSpeed _speed(Map<String, dynamic> raw) => PlayerSourceSpeed(
    quality: raw['quality']?.toString() ?? '未知',
    loadSpeed: raw['loadSpeed']?.toString() ?? '超时',
    pingTime: raw['pingTime']?.toString() ?? '超时',
  );

  Future<Result<T>> _guard<T>(
    String message,
    Future<T> Function() action,
  ) async {
    try {
      return Success<T>(await action());
    } catch (error, stackTrace) {
      return FailureResult<T>(
        AppFailure(
          kind: FailureKind.network,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void dispose() => _m3u8Service.dispose();
}
