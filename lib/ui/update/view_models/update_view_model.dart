import '../../../data/repositories/update/update_repository.dart';
import '../../../domain/models/app_update_transfer.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';

final class UpdateViewModel extends ViewModel {
  UpdateViewModel({required UpdateRepository repository})
    : _repository = repository {
    download = _versionedCommand(_download);
    pause = Command0<void>(_repository.pause)..addListener(_commandChanged);
    resume = _versionedCommand(_repository.resume);
    cancel = Command0<void>(_repository.cancel)..addListener(_commandChanged);
    install = _versionedCommand(_repository.install);
    openRelease = Command0<void>(_openRelease)..addListener(_commandChanged);
    _repository.addListener(_repositoryChanged);
  }

  final UpdateRepository _repository;
  AppVersionInfo? _versionInfo;
  UpdateTransferState? _downloadInitialTransfer;
  final Map<Command<void>, String?> _commandVersions = {};

  late final Command0<void> download;
  late final Command0<void> pause;
  late final Command0<void> resume;
  late final Command0<void> cancel;
  late final Command0<void> install;
  late final Command0<void> openRelease;

  AppVersionInfo? get versionInfo => _versionInfo;
  bool get canDownloadInApp =>
      _repository.supportsInAppDownload && _versionInfo?.androidAsset != null;
  bool get transferCommandRunning =>
      download.running ||
      pause.running ||
      resume.running ||
      cancel.running ||
      install.running;

  // 初始化和安装失败未必会进入 failed 状态，也需要提供外部下载兜底。
  bool get canUseBrowserDownload =>
      canDownloadInApp &&
      !transfer.isActive &&
      !transferCommandRunning &&
      (transfer.phase == UpdateTransferPhase.failed ||
          transfer.errorMessage != null ||
          [download, resume, install].any(
            (command) =>
                command.failure != null &&
                _commandVersions[command] == _versionInfo?.latestVersion,
          ));

  // 保留命令的真实结果，同时将失败兜底限定在发起操作的版本。
  // 不能只在 prepare 时清空结果，旧版本的在途操作仍可能稍后失败。
  Command0<void> _versionedCommand(CommandAction0<void> action) {
    late final Command0<void> command;
    command = Command0<void>(() {
      _commandVersions[command] = _versionInfo?.latestVersion;
      return action();
    })..addListener(_commandChanged);
    return command;
  }

  UpdateTransferState get transfer {
    final value = _repository.transfer;
    return value.version == _versionInfo?.latestVersion
        ? value
        : const UpdateTransferState();
  }

  /// 准备、排队属于同一次下载呈现；暂停/继续等待确认时保留原操作文案。
  /// 这里只合并展示阶段，真实任务状态与操作校验仍由 Repository 持有。
  UpdateTransferState get displayTransfer {
    final value = transfer;
    if (download.running &&
        _commandVersions[download] == _versionInfo?.latestVersion &&
        const {
          UpdateTransferPhase.idle,
          UpdateTransferPhase.cancelled,
          UpdateTransferPhase.failed,
        }.contains(value.phase) &&
        identical(_repository.transfer, _downloadInitialTransfer)) {
      return UpdateTransferState(
        phase: UpdateTransferPhase.queued,
        version: _versionInfo?.latestVersion,
        asset: _versionInfo?.androidAsset,
        totalBytes: _versionInfo?.androidAsset?.size ?? 0,
      );
    }
    if (resume.running &&
        _commandVersions[resume] == _versionInfo?.latestVersion &&
        value.phase == UpdateTransferPhase.queued) {
      return value.copyWith(phase: UpdateTransferPhase.paused);
    }
    return value;
  }

  void prepare(AppVersionInfo versionInfo) {
    if (_versionInfo == versionInfo) {
      return;
    }
    _versionInfo = versionInfo;
    notifyIfActive();
  }

  Future<Result<void>> _download() {
    _downloadInitialTransfer = _repository.transfer;
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
    ]) {
      command
        ..removeListener(_commandChanged)
        ..dispose();
    }
    _commandVersions.clear();
    super.dispose();
  }
}
