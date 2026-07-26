import '../../../data/repositories/live_repository.dart';
import '../../../domain/models/epg_program.dart';
import '../../../domain/models/live_channel.dart';
import '../../../domain/models/live_source.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'live_player_ui_state.dart';

final class LivePlayerViewModel extends ViewModel {
  LivePlayerViewModel({
    required LiveRepository repository,
    required LiveChannel channel,
    required LiveSource source,
  }) : _repository = repository,
       _state = LivePlayerUiState(
         currentChannel: channel,
         currentSource: source,
       );

  final LiveRepository _repository;
  LivePlayerUiState _state;
  int _requestGeneration = 0;

  LivePlayerUiState get state => _state;

  Future<void> initialize() async {
    final sources = await _repository.getLiveSources();
    final channels = await _repository.getLiveChannels(
      _state.currentSource.key,
    );
    _setState(
      _state.copyWith(
        sources: sources.valueOrNull ?? const <LiveSource>[],
        channels: channels.valueOrNull ?? const <LiveChannel>[],
        error:
            sources.failureOrNull?.message ?? channels.failureOrNull?.message,
      ),
    );
    await _loadEpg();
  }

  Future<Result<void>> switchChannel(LiveChannel channel) async {
    _requestGeneration++;
    _setState(_state.copyWith(currentChannel: channel, error: null));
    return _loadEpg();
  }

  Future<Result<void>> switchSource(LiveSource source) async {
    final generation = ++_requestGeneration;
    _setState(
      _state.copyWith(
        currentSource: source,
        selectedGroup: '全部',
        channels: const <LiveChannel>[],
        programs: null,
        loadingEpg: true,
        error: null,
      ),
    );
    final result = await _repository.getLiveChannels(source.key);
    if (generation != _requestGeneration) {
      return const Success<void>(null);
    }
    if (result case FailureResult<List<LiveChannel>>(:final failure)) {
      _setState(_state.copyWith(loadingEpg: false, error: failure.message));
      return FailureResult(failure);
    }
    final channels = result.valueOrNull ?? const <LiveChannel>[];
    if (channels.isEmpty) {
      const failure = AppFailure(
        kind: FailureKind.notFound,
        message: '该直播源暂无频道',
      );
      _setState(_state.copyWith(loadingEpg: false, error: failure.message));
      return const FailureResult<void>(failure);
    }
    _setState(
      _state.copyWith(channels: channels, currentChannel: channels.first),
    );
    return _loadEpg(generation: generation);
  }

  void selectGroup(String group) {
    _setState(_state.copyWith(selectedGroup: group));
  }

  Future<Result<void>> _loadEpg({int? generation}) async {
    final activeGeneration = generation ?? ++_requestGeneration;
    final channel = _state.currentChannel;
    if (channel.tvgId.isEmpty) {
      _setState(_state.copyWith(programs: null, loadingEpg: false));
      return const Success<void>(null);
    }
    _setState(_state.copyWith(loadingEpg: true, error: null));
    final result = await _repository.getLiveEpg(
      channel.tvgId,
      _state.currentSource.key,
    );
    if (activeGeneration != _requestGeneration) {
      return const Success<void>(null);
    }
    if (result case FailureResult(:final failure)) {
      _setState(
        _state.copyWith(
          programs: null,
          loadingEpg: false,
          error: failure.message,
        ),
      );
      return FailureResult(failure);
    }
    final EpgData? epg = result.valueOrNull;
    _setState(
      _state.copyWith(programs: epg?.programs, loadingEpg: false, error: null),
    );
    return const Success<void>(null);
  }

  void _setState(LivePlayerUiState value) =>
      updateState(_state, value, (next) => _state = next);
}
