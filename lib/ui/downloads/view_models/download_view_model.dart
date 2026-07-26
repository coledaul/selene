import '../../../data/repositories/download_repository.dart';
import '../../../domain/models/video_download_task.dart';
import '../../../domain/models/search_result.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'download_ui_state.dart';

final class DownloadViewModel extends ViewModel {
  DownloadViewModel({required DownloadRepository repository})
    : _repository = repository {
    initialize = Command0<void>(_initialize)..addListener(_notifyCommand);
    setConcurrency = Command1<void, int>(_setConcurrency)
      ..addListener(_notifyCommand);
    retry = Command1<void, String>(_retry)..addListener(_notifyCommand);
    cancel = Command1<void, String>(_cancel)..addListener(_notifyCommand);
    delete = Command1<void, String>(_delete)..addListener(_notifyCommand);
    _repository.addListener(_sync);
    _sync();
  }

  final DownloadRepository _repository;
  DownloadUiState _state = const DownloadUiState();

  late final Command0<void> initialize;
  late final Command1<void, int> setConcurrency;
  late final Command1<void, String> retry;
  late final Command1<void, String> cancel;
  late final Command1<void, String> delete;

  DownloadUiState get state => _state;

  Future<Result<List<VideoDownloadTask>>> enqueueAll(
    Iterable<VideoDownloadRequest> requests,
  ) async {
    try {
      return Success(await _repository.enqueueAll(requests));
    } catch (error, stackTrace) {
      return _failure('创建下载任务失败', error, stackTrace);
    }
  }

  Future<Result<List<VideoDownloadTask>>> enqueueEpisodes({
    required SearchResult detail,
    required Iterable<int> episodeIndexes,
  }) async {
    try {
      return Success(
        await _repository.enqueueEpisodes(
          detail: detail,
          episodeIndexes: episodeIndexes,
        ),
      );
    } catch (error, stackTrace) {
      return _failure('创建下载任务失败', error, stackTrace);
    }
  }

  Future<String?> completedPathFor({
    required String source,
    required String contentId,
    required int episodeIndex,
  }) => _repository.completedPathFor(
    source: source,
    contentId: contentId,
    episodeIndex: episodeIndex,
  );

  Future<Result<void>> _initialize() =>
      _run(_repository.initialize, '下载任务初始化失败');

  Future<Result<void>> _setConcurrency(int value) =>
      _run(() => _repository.setMaxConcurrentDownloads(value), '下载设置保存失败');

  Future<Result<void>> _retry(String taskId) =>
      _run(() => _repository.retry(taskId), '重试下载失败');

  Future<Result<void>> _cancel(String taskId) =>
      _run(() => _repository.cancel(taskId), '取消下载失败');

  Future<Result<void>> _delete(String taskId) =>
      _run(() => _repository.delete(taskId), '删除下载失败');

  Future<Result<void>> _run(
    Future<void> Function() action,
    String message,
  ) async {
    try {
      await action();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return _failure(message, error, stackTrace);
    }
  }

  FailureResult<T> _failure<T>(
    String message,
    Object error,
    StackTrace stackTrace,
  ) => FailureResult<T>(
    AppFailure(
      kind: FailureKind.storage,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    ),
  );

  void _sync() {
    final value = DownloadUiState(
      tasks: _repository.tasks,
      initialized: _repository.isInitialized,
      initializationError: _repository.initializationError,
      maxConcurrentDownloads: _repository.maxConcurrentDownloads,
    );
    updateState(_state, value, (next) => _state = next);
  }

  void _notifyCommand() => notifyIfActive();

  @override
  void dispose() {
    _repository.removeListener(_sync);
    for (final command in <Command<void>>[
      initialize,
      setConcurrency,
      retry,
      cancel,
      delete,
    ]) {
      command
        ..removeListener(_notifyCommand)
        ..dispose();
    }
    super.dispose();
  }
}
