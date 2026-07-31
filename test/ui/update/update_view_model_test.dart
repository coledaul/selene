import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/ui/update/view_models/update_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('只在 Repository 支持且 Release 有可信 APK 时启用应用内下载', () {
    final repository = _FakeUpdateRepository(supported: true);
    final viewModel = UpdateViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    viewModel.prepare(_version());

    expect(viewModel.canDownloadInApp, isTrue);
    expect(viewModel.versionInfo, _version());
  });

  test('命令统一委托 Repository 并同步任务状态', () async {
    final repository = _FakeUpdateRepository(supported: true);
    final viewModel = UpdateViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    viewModel.prepare(_version());

    await viewModel.download.execute();
    repository.setTransfer(
      const UpdateTransferState(
        phase: UpdateTransferPhase.downloading,
        version: '1.8.3',
        progress: 0.5,
      ),
    );

    expect(repository.downloadCount, 1);
    expect(viewModel.transfer.phase, UpdateTransferPhase.downloading);
    expect(viewModel.transfer.progress, 0.5);
  });
}

AppVersionInfo _version() => AppVersionInfo(
  currentVersion: '1.8.2',
  latestVersion: '1.8.3',
  releaseNotes: '',
  releaseUri: Uri.parse(
    'https://github.com/coledaul/selene/releases/tag/v1.8.3',
  ),
  androidAsset: AppReleaseAsset(
    fileName: 'selene-1.8.3-armv8.apk',
    downloadUri: Uri.parse(
      'https://github.com/coledaul/selene/releases/download/'
      'v1.8.3/selene-1.8.3-armv8.apk',
    ),
    size: 66,
    sha256: 'a' * 64,
    architecture: AndroidArchitecture.arm64,
  ),
);

final class _FakeUpdateRepository extends ChangeNotifier
    implements UpdateRepository {
  _FakeUpdateRepository({required bool supported}) : _supported = supported;

  final bool _supported;
  UpdateTransferState _transfer = const UpdateTransferState();
  int downloadCount = 0;

  @override
  bool get supportsInAppDownload => _supported;

  @override
  UpdateDownloadSource get downloadSource => UpdateDownloadSource.automatic;

  @override
  UpdateTransferState get transfer => _transfer;

  void setTransfer(UpdateTransferState value) {
    _transfer = value;
    notifyListeners();
  }

  @override
  Future<Result<void>> startDownload(AppVersionInfo versionInfo) async {
    downloadCount++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> cancel() async => const Success<void>(null);

  @override
  Future<Result<void>> install() async => const Success<void>(null);

  @override
  Future<Result<void>> openRelease(AppVersionInfo versionInfo) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> pause() async => const Success<void>(null);

  @override
  Future<Result<void>> resume() async => const Success<void>(null);

  @override
  Future<Result<void>> setDownloadSource(UpdateDownloadSource source) async =>
      const Success<void>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
