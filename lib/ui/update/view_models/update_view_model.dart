import '../../../data/repositories/update/update_repository.dart';
import '../../../domain/models/app_update_transfer.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';

final class UpdateViewModel extends ViewModel {
  UpdateViewModel({required UpdateRepository repository})
    : _repository = repository {
    download = Command0<void>(_download)..addListener(_commandChanged);
    pause = Command0<void>(_repository.pause)..addListener(_commandChanged);
    resume = Command0<void>(_repository.resume)..addListener(_commandChanged);
    cancel = Command0<void>(_repository.cancel)..addListener(_commandChanged);
    install = Command0<void>(_repository.install)..addListener(_commandChanged);
    openRelease = Command0<void>(_openRelease)..addListener(_commandChanged);
    setSource = Command1<void, UpdateDownloadSource>(
      _repository.setDownloadSource,
    )..addListener(_commandChanged);
    _repository.addListener(_repositoryChanged);
  }

  final UpdateRepository _repository;
  AppVersionInfo? _versionInfo;

  late final Command0<void> download;
  late final Command0<void> pause;
  late final Command0<void> resume;
  late final Command0<void> cancel;
  late final Command0<void> install;
  late final Command0<void> openRelease;
  late final Command1<void, UpdateDownloadSource> setSource;

  AppVersionInfo? get versionInfo => _versionInfo;
  bool get canDownloadInApp =>
      _repository.supportsInAppDownload && _versionInfo?.androidAsset != null;
  UpdateDownloadSource get downloadSource => _repository.downloadSource;

  UpdateTransferState get transfer {
    final value = _repository.transfer;
    return value.version == _versionInfo?.latestVersion
        ? value
        : UpdateTransferState(requestedSource: downloadSource);
  }

  void prepare(AppVersionInfo versionInfo) {
    if (_versionInfo == versionInfo) {
      return;
    }
    _versionInfo = versionInfo;
    notifyIfActive();
  }

  Future<Result<void>> _download() {
    final versionInfo = _versionInfo;
    return versionInfo == null
        ? Future<Result<void>>.value(
            const FailureResult(
              AppFailure(kind: FailureKind.validation, message: '缺少更新版本信息'),
            ),
          )
        : _repository.startDownload(versionInfo);
  }

  Future<Result<void>> _openRelease() {
    final versionInfo = _versionInfo;
    return versionInfo == null
        ? Future<Result<void>>.value(
            const FailureResult(
              AppFailure(kind: FailureKind.validation, message: '缺少更新版本信息'),
            ),
          )
        : _repository.openRelease(versionInfo);
  }

  void _repositoryChanged() => notifyIfActive();
  void _commandChanged() => notifyIfActive();

  @override
  void dispose() {
    _repository.removeListener(_repositoryChanged);
    for (final command in <Command<void>>[
      download,
      pause,
      resume,
      cancel,
      install,
      openRelease,
      setSource,
    ]) {
      command
        ..removeListener(_commandChanged)
        ..dispose();
    }
    super.dispose();
  }
}
