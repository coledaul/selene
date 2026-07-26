import '../../../data/repositories/metadata_repository.dart';
import 'view_model.dart';
import 'video_metadata_ui_state.dart';

final class VideoMetadataViewModel extends ViewModel {
  VideoMetadataViewModel({required MetadataRepository repository})
    : _repository = repository;

  final MetadataRepository _repository;
  VideoMetadataUiState _state = const VideoMetadataUiState();
  int _doubanGeneration = 0;
  int _bangumiGeneration = 0;

  VideoMetadataUiState get state => _state;

  Future<void> loadDouban(String id) async {
    final generation = ++_doubanGeneration;
    _setState(_state.copyWith(loadingDouban: true, doubanError: null));
    final result = await _repository.getDoubanDetails(id);
    if (generation != _doubanGeneration) return;
    _setState(
      _state.copyWith(
        loadingDouban: false,
        doubanDetails: result.valueOrNull,
        doubanError: result.failureOrNull?.message,
      ),
    );
  }

  Future<void> loadBangumi(String id) async {
    final generation = ++_bangumiGeneration;
    _setState(_state.copyWith(loadingBangumi: true, bangumiError: null));
    final result = await _repository.getBangumiDetails(id);
    if (generation != _bangumiGeneration) return;
    _setState(
      _state.copyWith(
        loadingBangumi: false,
        bangumiDetails: result.valueOrNull,
        bangumiError: result.failureOrNull?.message,
      ),
    );
  }

  void _setState(VideoMetadataUiState value) =>
      updateState(_state, value, (next) => _state = next);

  @override
  void dispose() {
    _doubanGeneration++;
    _bangumiGeneration++;
    super.dispose();
  }
}
