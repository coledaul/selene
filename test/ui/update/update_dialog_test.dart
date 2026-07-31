import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:selene/data/repositories/theme_repository.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_theme_mode.dart';
import 'package:selene/domain/models/app_update_transfer.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/ui/core/view_models/theme_view_model.dart';
import 'package:selene/ui/update/view_models/update_view_model.dart';
import 'package:selene/ui/update/widgets/update_dialog.dart';
import 'package:selene/utils/result.dart';

void main() {
  testWidgets('非 Android 保持查看新版本并通过 Repository 打开 Release', (tester) async {
    final repository = _FakeUpdateRepository(supported: false);
    await tester.pumpWidget(_Harness(repository: repository));

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('查看新版本'), findsOneWidget);
    expect(find.text('应用内下载'), findsNothing);

    await tester.tap(find.text('查看新版本'));
    await tester.pumpAndSettle();

    expect(repository.openReleaseCount, 1);
  });

  testWidgets('Android 有可信 APK 时展示应用内下载和线路选择', (tester) async {
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(_Harness(repository: repository));

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('应用内下载'), findsOneWidget);
    expect(find.text('自动'), findsOneWidget);
    expect(find.text('使用浏览器下载'), findsOneWidget);

    await tester.tap(find.text('自动'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub 直连'), findsOneWidget);
    expect(find.text('加速地址'), findsOneWidget);
  });
}

final class _Harness extends StatelessWidget {
  const _Harness({required this.repository});

  final UpdateRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeViewModel(repository: _FakeThemeRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => UpdateViewModel(repository: repository),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => UpdateDialog.show(
                context,
                _version(),
                onDismissVersion: (_) async {},
              ),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
  }
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
  int openReleaseCount = 0;

  @override
  UpdateDownloadSource get downloadSource => UpdateDownloadSource.automatic;

  @override
  bool get supportsInAppDownload => _supported;

  @override
  UpdateTransferState get transfer => const UpdateTransferState();

  @override
  Future<Result<void>> openRelease(AppVersionInfo versionInfo) async {
    openReleaseCount++;
    return const Success<void>(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeThemeRepository extends ChangeNotifier
    implements ThemeRepository {
  @override
  bool get isDark => false;

  @override
  AppThemeMode get mode => AppThemeMode.light;

  @override
  Future<void> setMode(AppThemeMode mode) async {}
}
