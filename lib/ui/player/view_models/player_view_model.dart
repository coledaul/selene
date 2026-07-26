import '../../../data/repositories/download_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../domain/models/auth_models.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/douban_movie.dart';
import '../../../domain/models/play_record.dart';
import '../../../domain/models/player_models.dart';
import '../../../domain/models/search_result.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import '../../downloads/view_models/download_view_model.dart';
import 'player_ui_state.dart';

/// 播放页面的唯一业务状态机。
final class PlayerViewModel extends ViewModel {
  PlayerViewModel({
    required PlayerRepository repository,
    required DownloadRepository downloadRepository,
    required SearchRepository searchRepository,
    required SettingsRepository settingsRepository,
    required LibraryRepository libraryRepository,
    required SessionState sessionState,
  }) : _repository = repository,
       _downloadRepository = downloadRepository,
       _searchRepository = searchRepository,
       _settingsRepository = settingsRepository,
       _libraryRepository = libraryRepository,
       _sessionState = sessionState,
       downloads = DownloadViewModel(repository: downloadRepository);

  final PlayerRepository _repository;
  final DownloadRepository _downloadRepository;
  final SearchRepository _searchRepository;
  final SettingsRepository _settingsRepository;
  final LibraryRepository _libraryRepository;
  final SessionState _sessionState;
  final DownloadViewModel downloads;
  PlayerUiState _state = const PlayerUiState();
  int _loadGeneration = 0;

  PlayerUiState get state => _state;

  Future<Result<void>> load(PlayerRequest request) async {
    final generation = ++_loadGeneration;
    if (request.source == null &&
        request.id == null &&
        request.title.trim().isEmpty &&
        request.searchTitle?.trim().isNotEmpty != true) {
      return _fail('缺少必要参数', FailureKind.validation);
    }
    setRequest(request);
    _setLoading(0.1, '正在读取播放设置...', '⚙️');

    var warningMessage = <String>[];
    final settings = await _settingsRepository.load();
    if (!_isCurrent(generation)) return _cancelled();
    if (settings.isFailure) warningMessage.add('应用设置读取失败，已使用默认设置');
    final appSettings = settings.valueOrNull ?? const AppSettings();

    _setLoading(0.33, '正在搜索播放源...', '🔍');
    final sourcesResult = await searchSources(
      request,
      localSearchEnabled: appSettings.localSearch,
    );
    if (!_isCurrent(generation)) return _cancelled();
    if (sourcesResult.isFailure) {
      return _finishFailure(sourcesResult.failureOrNull!);
    }
    var sources = sourcesResult.valueOrNull!;

    final source = request.source?.trim() ?? '';
    final id = request.id?.trim() ?? '';
    if (source.isNotEmpty &&
        id.isNotEmpty &&
        !sources.any((item) => item.source == source && item.id == id)) {
      final detailResult = await fetchSourceDetail(
        source,
        id,
        localSearchEnabled: appSettings.localSearch,
      );
      if (!_isCurrent(generation)) return _cancelled();
      if (detailResult.isFailure) {
        return _finishFailure(detailResult.failureOrNull!);
      }
      sources = detailResult.valueOrNull!;
    }
    if (sources.isEmpty) return _finishFailure(_failure('未找到匹配结果'));
    setSources(sources);

    SearchResult selected = sources.first;
    if (source.isNotEmpty && id.isNotEmpty && !request.prefer) {
      final specified = sources.where(
        (item) => item.source == source && item.id == id,
      );
      if (specified.isNotEmpty) selected = specified.first;
    } else if (appSettings.preferSpeedTest) {
      _setLoading(0.66, '正在优选最佳播放源...', '⚡');
      final preferred = await _repository.preferBestSource(sources);
      if (!_isCurrent(generation)) return _cancelled();
      if (preferred.isFailure) {
        warningMessage.add('播放源优选失败，已使用首个可用来源');
      } else {
        selected = preferred.valueOrNull!.source;
        setSourceSpeeds(preferred.valueOrNull!.speeds);
      }
    }

    final shouldLoadMetadata = applyDetail(selected);
    updateFavoriteState(
      _libraryRepository.isFavorited(selected.source, selected.id),
    );
    final resumeResult = await _libraryRepository.getPlayRecords();
    if (!_isCurrent(generation)) return _cancelled();
    if (resumeResult.isFailure) warningMessage.add('播放记录读取失败，已从头播放');
    final records = resumeResult.valueOrNull ?? const <PlayRecord>[];
    final matching = records.where(
      (record) => record.source == selected.source && record.id == selected.id,
    );
    final resume = matching.isEmpty
        ? null
        : PlayerResume(
            episodeIndex: matching.first.index > 0
                ? matching.first.index - 1
                : 0,
            playTime: matching.first.playTime,
          );
    _setState(
      _state.copyWith(
        resumeEpisodeIndex: resume?.episodeIndex ?? 0,
        resumePlayTime: resume?.playTime ?? 0,
      ),
    );

    if (shouldLoadMetadata && _state.doubanId > 0) {
      final metadata = await _repository.getDoubanDetails(_state.doubanId);
      if (!_isCurrent(generation)) return _cancelled();
      if (metadata.isSuccess) {
        setDoubanDetails(metadata.valueOrNull);
      } else {
        warningMessage.add('影片扩展信息加载失败');
      }
    }
    _setState(
      _state.copyWith(
        loading: false,
        loadingProgress: 1,
        loadingMessage: '准备就绪，即将开始播放...',
        loadingEmoji: '✨',
        errorMessage: null,
        warningMessage: warningMessage.isEmpty
            ? null
            : warningMessage.join('；'),
      ),
    );
    return const Success<void>(null);
  }

  Future<Result<List<SearchResult>>> searchSources(
    PlayerRequest request, {
    bool? localSearchEnabled,
  }) async {
    final enabled = localSearchEnabled ?? await _localSearchEnabled();
    final result = _sessionState.status == AuthStatus.localMode || enabled
        ? await _searchRepository.searchLocal(
            request.searchTitle?.trim().isNotEmpty == true
                ? request.searchTitle!.trim()
                : request.title,
          )
        : await _repository.searchRemoteSources(request);
    if (result.isFailure) return result;
    return Success<List<SearchResult>>(
      result.valueOrNull!
          .where((item) => _matchesRequest(item, request))
          .toList(growable: false),
    );
  }

  Future<Result<List<SearchResult>>> fetchSourceDetail(
    String source,
    String id, {
    bool? localSearchEnabled,
  }) async {
    final enabled = localSearchEnabled ?? await _localSearchEnabled();
    return _sessionState.status == AuthStatus.localMode || enabled
        ? _searchRepository.getLocalDetail(source, id)
        : _repository.fetchRemoteSourceDetail(source, id);
  }

  Future<bool> _localSearchEnabled() async {
    final settings = await _settingsRepository.load();
    return settings.valueOrNull?.localSearch ?? false;
  }

  bool _matchesRequest(SearchResult result, PlayerRequest request) {
    final normalizedTitle = request.title.replaceAll(' ', '').toLowerCase();
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
  }

  void setRequest(PlayerRequest request) {
    _setState(
      _state.copyWith(
        currentSource: request.source ?? '',
        currentId: request.id ?? '',
        videoTitle: request.title,
        videoYear: request.year ?? '',
        searchTitle: request.searchTitle ?? '',
        preferSource: request.prefer,
        errorMessage: null,
        warningMessage: null,
      ),
    );
  }

  void setSources(List<SearchResult> sources) =>
      _setState(_state.copyWith(sources: List.unmodifiable(sources)));

  void setCurrentDetail(SearchResult? detail) =>
      _setState(_state.copyWith(currentDetail: detail));

  bool applyDetail(SearchResult detail) {
    final oldDoubanId = _state.doubanId;
    var doubanId = detail.doubanId ?? 0;
    if (doubanId <= 0) {
      final counts = <int, int>{};
      for (final source in _state.sources) {
        final id = source.doubanId;
        if (id != null && id > 0) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (counts.isNotEmpty) {
        doubanId = counts.entries
            .reduce((left, right) => left.value > right.value ? left : right)
            .key;
      }
    }
    _setState(
      _state.copyWith(
        currentDetail: detail,
        videoTitle: detail.title,
        videoDescription: detail.desc ?? '',
        videoYear: detail.year,
        videoCover: detail.poster,
        currentSource: detail.source,
        currentId: detail.id,
        totalEpisodes: detail.episodes.length,
        doubanId: doubanId,
      ),
    );
    return doubanId > 0 && doubanId != oldDoubanId;
  }

  void setEpisode(int index) =>
      _setState(_state.copyWith(currentEpisodeIndex: index));
  void updateFavoriteState(bool value) =>
      _setState(_state.copyWith(favorite: value));

  void setDoubanDetails(DoubanMovieDetails? details) {
    var description = _state.videoDescription;
    final summary = details?.summary;
    if ((description.isEmpty || description == '暂无简介') &&
        summary != null &&
        summary.isNotEmpty) {
      description = summary;
    }
    _setState(
      _state.copyWith(doubanDetails: details, videoDescription: description),
    );
  }

  void setSourceSpeeds(Map<String, PlayerSourceSpeed> speeds) =>
      _setState(_state.copyWith(sourceSpeeds: Map.unmodifiable(speeds)));
  void clearSourceSpeeds() =>
      _setState(_state.copyWith(sourceSpeeds: const {}));
  void setSourceSpeed(String id, PlayerSourceSpeed speed) => _setState(
    _state.copyWith(sourceSpeeds: {..._state.sourceSpeeds, id: speed}),
  );

  Future<Result<PreferredPlayerSource>> preferBestSource(
    List<SearchResult> sources,
  ) => _repository.preferBestSource(sources);
  Future<Result<DoubanMovieDetails?>> getDoubanDetails(int id) =>
      _repository.getDoubanDetails(id);
  Future<Result<Map<String, PlayerSourceSpeed>>> testSources(
    List<SearchResult> sources, {
    void Function(String sourceId, PlayerSourceSpeed speed)? onResult,
  }) => _repository.testSources(sources, onResult: onResult);

  bool isFavorited(String source, String id) =>
      _libraryRepository.isFavorited(source, id);

  Future<Result<bool>> setFavorite({
    required bool favorite,
    required PlayRecord record,
  }) async {
    final result = favorite
        ? await _libraryRepository
              .addFavorite(record.source, record.id, <String, Object?>{
                'cover': record.cover,
                'save_time': DateTime.now().millisecondsSinceEpoch,
                'source_name': record.sourceName,
                'title': record.title,
                'total_episodes': record.totalEpisodes,
                'year': record.year,
              })
        : await _libraryRepository.removeFavorite(record.source, record.id);
    if (result.isFailure) return FailureResult(result.failureOrNull!);
    updateFavoriteState(favorite);
    return Success<bool>(favorite);
  }

  Future<Result<void>> savePlayRecord(PlayRecord record) =>
      _libraryRepository.savePlayRecord(record);
  Future<Result<void>> deletePlayRecord(String source, String id) =>
      _libraryRepository.deletePlayRecord(source, id);

  Future<Result<String>> resolvePlaybackUrl({
    required String mediaUrl,
    required String source,
    required String contentId,
    required int episodeIndex,
  }) async {
    try {
      final localPath = await _downloadRepository.completedPathFor(
        source: source,
        contentId: contentId,
        episodeIndex: episodeIndex,
      );
      if (localPath != null) return Success<String>(localPath);
    } catch (error, stackTrace) {
      return FailureResult<String>(
        AppFailure(
          kind: FailureKind.storage,
          message: '读取离线视频失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
    return _repository.resolveRemotePlaybackUrl(mediaUrl);
  }

  void _setLoading(double progress, String message, String emoji) => _setState(
    _state.copyWith(
      loading: true,
      loadingProgress: progress,
      loadingMessage: message,
      loadingEmoji: emoji,
      errorMessage: null,
    ),
  );

  FailureResult<void> _finishFailure(AppFailure failure) {
    _setState(_state.copyWith(loading: false, errorMessage: failure.message));
    return FailureResult<void>(failure);
  }

  FailureResult<void> _fail(String message, FailureKind kind) =>
      _finishFailure(AppFailure(kind: kind, message: message));
  AppFailure _failure(String message) =>
      AppFailure(kind: FailureKind.notFound, message: message);
  FailureResult<void> _cancelled() => const FailureResult<void>(
    AppFailure(kind: FailureKind.cancellation, message: '播放加载已取消'),
  );
  bool _isCurrent(int generation) => generation == _loadGeneration;

  void _setState(PlayerUiState value) =>
      updateState(_state, value, (next) => _state = next);

  @override
  void dispose() {
    _loadGeneration++;
    downloads.dispose();
    super.dispose();
  }
}
