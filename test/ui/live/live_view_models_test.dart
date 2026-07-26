import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/live_repository.dart';
import 'package:selene/domain/models/epg_program.dart';
import 'package:selene/domain/models/live_channel.dart';
import 'package:selene/domain/models/live_source.dart';
import 'package:selene/ui/live/view_models/live_player_view_model.dart';
import 'package:selene/ui/live/view_models/live_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('LiveViewModel', () {
    test('初始化加载直播源、频道并在 ViewModel 中完成分组', () async {
      final repository = _FakeLiveRepository();
      final viewModel = LiveViewModel(repository: repository);

      await viewModel.initialize();

      expect(viewModel.state.currentSource?.key, 'source-a');
      expect(viewModel.state.groups.map((group) => group.name), <String>[
        '新闻',
        '体育',
      ]);
      expect(viewModel.state.filteredChannels, hasLength(2));
      viewModel.selectGroup('体育');
      expect(viewModel.state.filteredChannels.single.id, 'channel-b');
      viewModel.dispose();
    });

    test('首次请求失败保留类型化错误而不是伪装为空列表', () async {
      final repository = _FakeLiveRepository()..sourcesFail = true;
      final viewModel = LiveViewModel(repository: repository);

      await viewModel.initialize();

      expect(viewModel.state.error, '直播源网络失败');
      expect(viewModel.state.loading, isFalse);
      viewModel.dispose();
    });
  });

  group('LivePlayerViewModel', () {
    test('切换直播源后选择首个频道并重新加载节目单', () async {
      final repository = _FakeLiveRepository();
      final viewModel = LivePlayerViewModel(
        repository: repository,
        channel: repository.channels.first,
        source: repository.sources.first,
      );
      await viewModel.initialize();
      final secondSource = _source('source-b');
      repository.sources = <LiveSource>[repository.sources.first, secondSource];
      repository.channels = <LiveChannel>[_channel('channel-c', '综合')];

      final result = await viewModel.switchSource(secondSource);

      expect(result, isA<Success<void>>());
      expect(viewModel.state.currentSource.key, 'source-b');
      expect(viewModel.state.currentChannel.id, 'channel-c');
      expect(viewModel.state.programs?.single.title, '当前节目');
      viewModel.dispose();
    });
  });
}

final class _FakeLiveRepository implements LiveRepository {
  List<LiveSource> sources = <LiveSource>[_source('source-a')];
  List<LiveChannel> channels = <LiveChannel>[
    _channel('channel-a', '新闻'),
    _channel('channel-b', '体育'),
  ];
  bool sourcesFail = false;

  @override
  Future<Result<List<LiveSource>>> getLiveSources({
    bool forceRefresh = false,
  }) async {
    if (sourcesFail) {
      return const FailureResult(
        AppFailure(kind: FailureKind.network, message: '直播源网络失败'),
      );
    }
    return Success<List<LiveSource>>(sources);
  }

  @override
  Future<Result<List<LiveChannel>>> getLiveChannels(
    String sourceKey, {
    bool forceRefresh = false,
  }) async => Success<List<LiveChannel>>(channels);

  @override
  Future<Result<EpgData?>> getLiveEpg(
    String tvgId,
    String sourceKey, {
    bool forceRefresh = false,
  }) async {
    return Success<EpgData?>(
      EpgData(
        tvgId: tvgId,
        source: sourceKey,
        epgUrl: '',
        programs: <EpgProgram>[
          EpgProgram(
            channelId: tvgId,
            title: '当前节目',
            startTime: DateTime.now().subtract(const Duration(minutes: 10)),
            endTime: DateTime.now().add(const Duration(minutes: 10)),
          ),
        ],
      ),
    );
  }

  @override
  void clearAllChannelsAndEpgCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LiveSource _source(String key) => LiveSource(
  key: key,
  name: key,
  url: 'https://example.com/$key.m3u',
  ua: '',
  epg: '',
  from: 'test',
  disabled: false,
);

LiveChannel _channel(String id, String group) => LiveChannel(
  id: id,
  tvgId: 'tvg-$id',
  name: id,
  logo: '',
  group: group,
  url: 'https://example.com/$id.m3u8',
);
