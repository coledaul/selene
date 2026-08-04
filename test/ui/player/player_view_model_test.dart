import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/download_repository.dart';
import 'package:selene/data/repositories/player_repository.dart';
import 'package:selene/data/repositories/search_repository.dart';
import 'package:selene/data/repositories/settings_repository.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/domain/models/app_settings.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/domain/models/player_models.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/player/playback_models.dart';
import 'package:selene/ui/player/view_models/player_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  late _FakeDownloadRepository downloadRepository;
  late _FakePlayerRepository playerRepository;
  late PlayerViewModel viewModel;

  setUp(() {
    downloadRepository = _FakeDownloadRepository();
    playerRepository = _FakePlayerRepository();
    viewModel = PlayerViewModel(
      repository: playerRepository,
      downloadRepository: downloadRepository,
      searchRepository: _FakeSearchRepository(),
      settingsRepository: _FakeSettingsRepository(),
      libraryRepository: _FakeLibraryRepository(),
      sessionState: _FakeSessionState(),
    );
  });

  tearDown(() {
    viewModel.dispose();
    downloadRepository.dispose();
  });

  test('播放请求被转换为不可变页面状态', () {
    viewModel.setRequest(
      const PlayerRequest(
        source: 'source-a',
        id: 'video-1',
        title: '测试影片',
        year: '2026',
        searchTitle: '检索标题',
        prefer: true,
      ),
    );

    expect(viewModel.state.currentSource, 'source-a');
    expect(viewModel.state.currentId, 'video-1');
    expect(viewModel.state.videoTitle, '测试影片');
    expect(viewModel.state.searchTitle, '检索标题');
    expect(viewModel.state.preferSource, isTrue);
  });

  test('详情缺少豆瓣 ID 时使用所有来源中出现次数最多的有效 ID', () {
    final selected = _result(source: 'selected');
    viewModel.setSources(<SearchResult>[
      selected,
      _result(source: 'source-b', doubanId: 42),
      _result(source: 'source-c', doubanId: 42),
      _result(source: 'source-d', doubanId: 7),
    ]);

    final shouldLoadMetadata = viewModel.applyDetail(selected);

    expect(shouldLoadMetadata, isTrue);
    expect(viewModel.state.currentDetail, same(selected));
    expect(viewModel.state.doubanId, 42);
    expect(viewModel.state.totalEpisodes, 2);
  });

  test('切换为相同豆瓣 ID 的来源时不重复请求详情', () {
    final first = _result(source: 'source-a', doubanId: 42);
    final second = _result(source: 'source-b', doubanId: 42);

    expect(viewModel.applyDetail(first), isTrue);
    expect(viewModel.applyDetail(second), isFalse);
  });

  test('仅在来源简介为空时使用豆瓣简介兜底', () {
    viewModel.applyDetail(_result(source: 'source-a', description: ''));
    viewModel.setDoubanDetails(_details(summary: '豆瓣简介'));
    expect(viewModel.state.videoDescription, '豆瓣简介');

    viewModel.applyDetail(_result(source: 'source-b', description: '来源简介'));
    viewModel.setDoubanDetails(_details(summary: '不应覆盖'));
    expect(viewModel.state.videoDescription, '来源简介');
  });

  test('测速结果以新映射发布且不受调用方后续修改影响', () {
    final speeds = <String, PlayerSourceSpeed>{
      'source-a': const PlayerSourceSpeed(
        quality: '1080P',
        loadSpeed: '2 MB/s',
        pingTime: '20 ms',
      ),
    };

    viewModel.setSourceSpeeds(speeds);
    speeds.clear();

    expect(viewModel.state.sourceSpeeds, hasLength(1));
    expect(
      () => viewModel.state.sourceSpeeds['source-b'] = const PlayerSourceSpeed(
        quality: '720P',
        loadSpeed: '1 MB/s',
        pingTime: '30 ms',
      ),
      throwsUnsupportedError,
    );
  });

  test('普通播放命中完成下载时显式返回本地媒体类型', () async {
    downloadRepository.completedPath = '/documents/downloads/episode.mkv';

    final result = await viewModel.resolvePlaybackMedia(
      mediaUrl: 'https://example.com/episode.m3u8',
      source: 'source-a',
      contentId: 'video-1',
      episodeIndex: 0,
    );

    expect(result, isA<Success<PlaybackMediaSource>>());
    expect(result.valueOrNull?.url, '/documents/downloads/episode.mkv');
    expect(result.valueOrNull?.kind, PlaybackMediaKind.localFile);
    expect(playerRepository.remotePlaybackResolutions, 0);
  });

  test('没有完成下载时返回远程网络点播媒体类型', () async {
    playerRepository.resolvedPlaybackUrl =
        'https://cdn.example.com/resolved.m3u8';

    final result = await viewModel.resolvePlaybackMedia(
      mediaUrl: 'https://example.com/episode.m3u8',
      source: 'source-a',
      contentId: 'video-1',
      episodeIndex: 0,
    );

    expect(result, isA<Success<PlaybackMediaSource>>());
    expect(result.valueOrNull?.url, playerRepository.resolvedPlaybackUrl);
    expect(result.valueOrNull?.kind, PlaybackMediaKind.networkVod);
    expect(playerRepository.remotePlaybackResolutions, 1);
  });

  test('DLNA 等远端播放目标跳过本机完成下载并解析远程地址', () async {
    downloadRepository.completedPath = '/documents/downloads/episode.mkv';
    playerRepository.resolvedPlaybackUrl =
        'https://cdn.example.com/resolved.m3u8';

    final result = await viewModel.resolvePlaybackMedia(
      mediaUrl: 'https://example.com/episode.m3u8',
      source: 'source-a',
      contentId: 'video-1',
      episodeIndex: 0,
      allowCompletedDownload: false,
    );

    expect(result, isA<Success<PlaybackMediaSource>>());
    expect(result.valueOrNull?.url, playerRepository.resolvedPlaybackUrl);
    expect(result.valueOrNull?.kind, PlaybackMediaKind.networkVod);
    expect(downloadRepository.completedPathLookups, 0);
    expect(playerRepository.remotePlaybackResolutions, 1);
  });

  test('读取完成下载失败时保留存储错误且不回退远程地址', () async {
    downloadRepository.completedPathError = StateError('read failed');

    final result = await viewModel.resolvePlaybackMedia(
      mediaUrl: 'https://example.com/episode.m3u8',
      source: 'source-a',
      contentId: 'video-1',
      episodeIndex: 0,
    );

    expect(result, isA<FailureResult<PlaybackMediaSource>>());
    expect(result.failureOrNull?.kind, FailureKind.storage);
    expect(result.failureOrNull?.message, '读取离线视频失败');
    expect(playerRepository.remotePlaybackResolutions, 0);
  });

  test('远程播放地址解析失败时保留原始失败类型和消息', () async {
    playerRepository.resolvePlaybackFailure = const AppFailure(
      kind: FailureKind.network,
      message: 'remote failed',
    );

    final result = await viewModel.resolvePlaybackMedia(
      mediaUrl: 'https://example.com/episode.m3u8',
      source: 'source-a',
      contentId: 'video-1',
      episodeIndex: 0,
    );

    expect(result, isA<FailureResult<PlaybackMediaSource>>());
    expect(result.failureOrNull, same(playerRepository.resolvePlaybackFailure));
  });

  test('首次加载由 ViewModel 完成来源选择、收藏和断点恢复', () async {
    final player = _FakePlayerRepository();
    final library = _FakeLibraryRepository(
      records: <PlayRecord>[
        PlayRecord(
          id: 'source-a-id',
          source: 'source-a',
          title: '测试影片',
          sourceName: 'source-a',
          year: '2026',
          cover: '',
          index: 2,
          totalEpisodes: 2,
          playTime: 35,
          totalTime: 120,
          saveTime: 1,
          searchTitle: '测试影片',
        ),
      ],
      favorite: true,
    );
    final model = PlayerViewModel(
      repository: player,
      downloadRepository: downloadRepository,
      searchRepository: _FakeSearchRepository(),
      settingsRepository: _FakeSettingsRepository(),
      libraryRepository: library,
      sessionState: _FakeSessionState(),
    );

    final result = await model.load(
      const PlayerRequest(title: '测试影片', year: '2026'),
    );

    expect(result, isA<Success<void>>());
    expect(player.remoteSearches, 1);
    expect(model.state.currentDetail?.source, 'source-a');
    expect(model.state.favorite, isTrue);
    expect(model.state.resumeEpisodeIndex, 1);
    expect(model.state.resumePlayTime, 35);
    expect(model.state.loading, isFalse);
    model.dispose();
  });

  test('非关键设置与播放记录失败时仍使用默认值完成播放加载', () async {
    final model = PlayerViewModel(
      repository: _FakePlayerRepository(),
      downloadRepository: downloadRepository,
      searchRepository: _FakeSearchRepository(),
      settingsRepository: _FailingSettingsRepository(),
      libraryRepository: _FailingLibraryRepository(),
      sessionState: _FakeSessionState(),
    );

    final result = await model.load(
      const PlayerRequest(title: '测试影片', year: '2026'),
    );

    expect(result, isA<Success<void>>());
    expect(model.state.currentDetail, isNotNull);
    expect(model.state.resumeEpisodeIndex, 0);
    expect(model.state.warningMessage, contains('应用设置读取失败'));
    expect(model.state.warningMessage, contains('播放记录读取失败'));
    model.dispose();
  });
}

SearchResult _result({
  required String source,
  int? doubanId,
  String? description,
}) => SearchResult(
  id: '$source-id',
  title: '测试影片',
  poster: 'poster.jpg',
  episodes: const <String>['episode-1', 'episode-2'],
  episodesTitles: const <String>['第 1 集', '第 2 集'],
  source: source,
  sourceName: source,
  year: '2026',
  desc: description,
  doubanId: doubanId,
);

DoubanMovieDetails _details({required String summary}) => DoubanMovieDetails(
  id: '42',
  title: '测试影片',
  poster: 'poster.jpg',
  year: '2026',
  summary: summary,
);

final class _FakePlayerRepository implements PlayerRepository {
  int remoteSearches = 0;
  int remotePlaybackResolutions = 0;
  String resolvedPlaybackUrl = 'https://example.com/resolved.m3u8';
  AppFailure? resolvePlaybackFailure;

  @override
  Future<Result<List<SearchResult>>> searchRemoteSources(
    PlayerRequest request,
  ) async {
    remoteSearches++;
    return Success<List<SearchResult>>(<SearchResult>[
      _result(source: 'source-a', doubanId: 42),
    ]);
  }

  @override
  Future<Result<DoubanMovieDetails?>> getDoubanDetails(int doubanId) async =>
      const Success<DoubanMovieDetails?>(null);

  @override
  Future<Result<PreferredPlayerSource>> preferBestSource(
    List<SearchResult> sources,
  ) async => Success<PreferredPlayerSource>(
    PreferredPlayerSource(source: sources.first, speeds: const {}),
  );

  @override
  Future<Result<String>> resolveRemotePlaybackUrl(String mediaUrl) async {
    remotePlaybackResolutions++;
    final failure = resolvePlaybackFailure;
    if (failure != null) return FailureResult<String>(failure);
    return Success<String>(resolvedPlaybackUrl);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<Result<AppSettings>> load() async => const FailureResult<AppSettings>(
    AppFailure(kind: FailureKind.storage, message: 'read failed'),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSearchRepository implements SearchRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FailingLibraryRepository implements LibraryRepository {
  @override
  Future<Result<List<PlayRecord>>> getPlayRecords({
    bool forceRefresh = false,
  }) async => const FailureResult<List<PlayRecord>>(
    AppFailure(kind: FailureKind.network, message: 'read failed'),
  );

  @override
  bool isFavorited(String source, String id) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Result<AppSettings>> load() async =>
      const Success<AppSettings>(AppSettings(preferSpeedTest: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({
    this.records = const <PlayRecord>[],
    this.favorite = false,
  });

  final List<PlayRecord> records;
  final bool favorite;

  @override
  Future<Result<List<PlayRecord>>> getPlayRecords({
    bool forceRefresh = false,
  }) async => Success<List<PlayRecord>>(records);

  @override
  bool isFavorited(String source, String id) => favorite;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSessionState implements SessionState {
  @override
  AuthStatus get status => AuthStatus.authenticated;
}

final class _FakeDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  String? completedPath;
  Object? completedPathError;
  int completedPathLookups = 0;

  @override
  List<VideoDownloadTask> tasks = <VideoDownloadTask>[];

  @override
  bool get isInitialized => true;

  @override
  String? get initializationError => null;

  @override
  int get maxConcurrentDownloads => 3;

  @override
  Future<String?> completedPathFor({
    required String source,
    required String contentId,
    required int episodeIndex,
  }) async {
    completedPathLookups++;
    final error = completedPathError;
    if (error != null) throw error;
    return completedPath;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
