import '../../../data/repositories/live_repository.dart';
import '../../../domain/models/live_channel.dart';
import '../../../domain/models/live_source.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'live_ui_state.dart';

final class LiveViewModel extends ViewModel {
  LiveViewModel({required LiveRepository repository})
    : _repository = repository;

  final LiveRepository _repository;
  LiveUiState _state = const LiveUiState();
  int _requestGeneration = 0;

  LiveUiState get state => _state;

  Future<void> initialize() => _load();

  Future<Result<void>> selectSource(LiveSource source) async {
    _setState(_state.copyWith(currentSource: source, selectedGroup: '全部'));
    return _loadChannels(source, loading: true);
  }

  void selectGroup(String group) {
    _setState(_state.copyWith(selectedGroup: group));
  }

  Future<Result<void>> refresh() async {
    _repository.clearAllChannelsAndEpgCache();
    _setState(_state.copyWith(refreshing: true, error: null, notice: null));
    final result = await _load(forceRefresh: true, refreshing: true);
    _setState(_state.copyWith(refreshing: false));
    return result;
  }

  void consumeNotice() {
    if (_state.notice != null) {
      _setState(_state.copyWith(notice: null));
    }
  }

  Future<Result<void>> _load({
    bool forceRefresh = false,
    bool refreshing = false,
  }) async {
    final generation = ++_requestGeneration;
    if (!refreshing) {
      _setState(_state.copyWith(loading: true, error: null));
    }
    final sourcesResult = await _repository.getLiveSources(
      forceRefresh: forceRefresh,
    );
    if (generation != _requestGeneration) {
      return const Success<void>(null);
    }
    if (sourcesResult case FailureResult<List<LiveSource>>(:final failure)) {
      _setFailure(failure, refreshing: refreshing);
      return FailureResult(failure);
    }

    final sources = sourcesResult.valueOrNull ?? const <LiveSource>[];
    if (sources.isEmpty) {
      const failure = AppFailure(kind: FailureKind.notFound, message: '暂无直播源');
      _setState(
        _state.copyWith(
          sources: const <LiveSource>[],
          groups: const <LiveChannelGroup>[],
          currentSource: null,
          loading: false,
          initialLoad: false,
          error: failure.message,
        ),
      );
      return const FailureResult<void>(failure);
    }

    final previousKey = _state.currentSource?.key;
    final source = sources.firstWhere(
      (item) => item.key == previousKey,
      orElse: () => sources.first,
    );
    final sourceChanged = previousKey != null && previousKey != source.key;
    _setState(
      _state.copyWith(
        sources: sources,
        currentSource: source,
        selectedGroup: sourceChanged ? '全部' : _state.selectedGroup,
        initialLoad: false,
        notice: sourceChanged ? '当前源已不存在，已切换到 ${source.name}' : null,
      ),
    );
    return _loadChannels(
      source,
      forceRefresh: forceRefresh,
      loading: !refreshing,
      generation: generation,
    );
  }

  Future<Result<void>> _loadChannels(
    LiveSource source, {
    bool forceRefresh = false,
    bool loading = false,
    int? generation,
  }) async {
    final activeGeneration = generation ?? ++_requestGeneration;
    if (loading) {
      _setState(_state.copyWith(loading: true, error: null));
    }
    final channelsResult = await _repository.getLiveChannels(
      source.key,
      forceRefresh: forceRefresh,
    );
    if (activeGeneration != _requestGeneration) {
      return const Success<void>(null);
    }
    if (channelsResult case FailureResult<List<LiveChannel>>(:final failure)) {
      _setFailure(failure, refreshing: false);
      return FailureResult(failure);
    }
    final channels = channelsResult.valueOrNull ?? const <LiveChannel>[];
    if (channels.isEmpty) {
      const failure = AppFailure(
        kind: FailureKind.notFound,
        message: '该直播源暂无频道',
      );
      _setState(
        _state.copyWith(
          groups: const <LiveChannelGroup>[],
          loading: false,
          error: failure.message,
        ),
      );
      return const FailureResult<void>(failure);
    }

    final grouped = <String, List<LiveChannel>>{};
    for (final channel in channels) {
      final name = channel.group.isEmpty ? '未分组' : channel.group;
      grouped.putIfAbsent(name, () => <LiveChannel>[]).add(channel);
    }
    final groups = grouped.entries
        .map(
          (entry) => LiveChannelGroup(
            name: entry.key,
            channels: List<LiveChannel>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false);
    _setState(_state.copyWith(groups: groups, loading: false, error: null));
    return const Success<void>(null);
  }

  void _setFailure(AppFailure failure, {required bool refreshing}) {
    _setState(
      _state.copyWith(
        loading: false,
        initialLoad: false,
        refreshing: refreshing,
        error: failure.message,
      ),
    );
  }

  void _setState(LiveUiState value) =>
      updateState(_state, value, (next) => _state = next);
}
