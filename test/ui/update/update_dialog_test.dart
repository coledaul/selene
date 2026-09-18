import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/ui/core/themes/app_theme.dart';
import 'package:selene/ui/update/view_models/update_view_model.dart';
import 'package:selene/ui/update/widgets/update_dialog.dart';
import 'package:selene/ui/update/widgets/update_transfer_panel.dart';
import 'package:selene/utils/result.dart';

void main() {
  testWidgets('续传失败仍能取消任务并重新下载，取消后保留浏览器兜底', (tester) async {
    final repository = _FakeUpdateRepository(supported: true)
      ..resumeResult = const FailureResult(
        AppFailure(kind: FailureKind.platform, message: '继续更新下载失败'),
      )
      ..setPhase(UpdateTransferPhase.paused);
    await tester.pumpWidget(_Harness(repository: repository));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续下载'));
    await tester.pumpAndSettle();
    expect(repository.transfer.phase, UpdateTransferPhase.paused);
    expect(find.text('取消下载').hitTestable(), findsOneWidget);
    await tester.tap(find.text('取消下载'));
    await tester.pumpAndSettle();
    expect(repository.cancelCount, 1);
    expect(find.text('浏览器下载').hitTestable(), findsOneWidget);
    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();
    expect(repository.downloadCount, 1);
    expect(repository.transfer.phase, UpdateTransferPhase.downloading);
  });

  testWidgets('关闭弹窗后外部打开操作晚返回不能继续关闭底层页面', (tester) async {
    final opening = Completer<Result<void>>();
    final repository = _FakeUpdateRepository(supported: false)
      ..pendingRelease = opening;
    await tester.pumpWidget(_Harness(repository: repository));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看新版本'));
    await tester.pump();
    await tester.tap(find.byTooltip('关闭更新弹窗'));
    opening.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    expect(find.text('show'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('右上角关闭只结束本次弹窗，次操作居左且主操作居右', (tester) async {
    var ignored = 0;
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(
      _Harness(repository: repository, onDismiss: (_) async => ignored++),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('稍后'), findsNothing);
    final close = find.byTooltip('关闭更新弹窗');
    expect(close.hitTestable(), findsOneWidget);
    final primary = tester.getRect(
      find.byKey(const ValueKey("update-primary-action")),
    );
    final secondary = tester.getRect(
      find.byKey(const ValueKey('update-secondary-action')),
    );
    expect(primary.center.dy, secondary.center.dy);
    final actionsBounds = tester.getRect(
      find.byKey(const ValueKey('update-actions-layout')),
    );
    expect(secondary.left, actionsBounds.left);
    expect(primary.right, actionsBounds.right);
    expect(primary.left - secondary.right, 12);
    expect(primary.size, secondary.size);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(ignored, 0);
    expect(repository.cancelCount, 0);
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('立即更新'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 3.0]) {
      testWidgets('暂停继续文字柔和过渡且快速反向不跳位 dark=$dark scale=$scale', (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = _FakeUpdateRepository(supported: true);
        await tester.pumpWidget(
          _Harness(
            repository: repository,
            dark: dark,
            textScale: scale,
            disableAnimations: false,
          ),
        );
        await tester.tap(find.text('show'));
        await tester.pumpAndSettle();
        repository.setPhase(UpdateTransferPhase.downloading);
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey("update-primary-action"));
        final buttonBounds = tester.getRect(button);
        final panelBounds = tester.getRect(find.byType(UpdateTransferPanel));
        final labelBounds = tester.getRect(find.text('暂停下载'));
        double labelOpacity(String label) {
          final fade = find.ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedOpacity),
          );
          expect(fade, findsOneWidget);
          return tester
              .widget<FadeTransition>(
                find
                    .descendant(of: fade, matching: find.byType(FadeTransition))
                    .first,
              )
              .opacity
              .value;
        }

        await tester.tap(find.text('暂停下载'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(labelOpacity('继续下载'), inExclusiveRange(0, 1));
        expect(labelOpacity('暂停下载'), inExclusiveRange(0, 1));
        expect(tester.getRect(button), buttonBounds);
        expect(tester.getRect(find.byType(UpdateTransferPanel)), panelBounds);
        expect(tester.getRect(find.text('继续下载')), labelBounds);
        // 动画不能锁住操作；中途反向只向最新状态过渡。
        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(labelOpacity('继续下载'), 1);
        expect(labelOpacity('暂停下载'), 0);
        expect(tester.getRect(button), buttonBounds);
        expect(tester.getRect(find.byType(UpdateTransferPanel)), panelBounds);
        expect(repository.pauseCount, 2);
        expect(repository.resumeCount, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('开始下载只切换一次面板，暂停继续不展示中间文案或移动按钮', (tester) async {
    final starting = Completer<Result<void>>();
    final pausing = Completer<Result<void>>();
    final resuming = Completer<Result<void>>();
    final repository = _FakeUpdateRepository(supported: true)
      ..pendingDownload = starting
      ..pendingPause = pausing
      ..pendingResume = resuming;
    await tester.pumpWidget(_Harness(repository: repository, notes: '更新说明'));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('立即更新'));
    await tester.pump();
    expect(find.byType(UpdateTransferPanel), findsOneWidget);
    expect(find.text('暂停下载'), findsOneWidget);
    expect(find.text('请稍候…'), findsNothing);
    final button = find.byKey(const ValueKey("update-primary-action"));
    final bounds = tester.getRect(button);
    repository.setPhase(UpdateTransferPhase.queued);
    await tester.pump();
    expect(find.text('准备下载…'), findsNothing);
    expect(tester.getRect(button), bounds);
    starting.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    expect(tester.getRect(button), bounds);

    // 保留上一帧的回调，覆盖一帧内多次触发与反向操作的窗口。
    final stalePause = tester.widget<FilledButton>(button).onPressed!;
    stalePause();
    stalePause();
    await tester.pump();
    expect(repository.pauseCount, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('暂停下载'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.getRect(button), bounds);
    pausing.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    expect(find.text('继续下载'), findsOneWidget);
    expect(tester.getRect(button), bounds);
    await tester.tap(find.text('继续下载'));
    await tester.pump();
    expect(find.text('继续下载'), findsOneWidget);
    expect(find.text('下载已暂停'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.getRect(button), bounds);
    resuming.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    expect(find.text('暂停下载'), findsOneWidget);
    expect(tester.getRect(button), bounds);
    expect(repository.downloadCount, 1);
    expect(repository.resumeCount, 1);
  });

  for (final dark in [false, true]) {
    for (final inApp in [false, true]) {
      testWidgets('浏览器打开期间有等待提示且失败恢复 dark=$dark inApp=$inApp', (tester) async {
        final gate = Completer<Result<void>>();
        final repository = _FakeUpdateRepository(supported: inApp)
          ..pendingRelease = gate;
        await tester.pumpWidget(_Harness(repository: repository, dark: dark));
        await tester.tap(find.text('show'));
        await tester.pumpAndSettle();
        if (inApp) {
          repository.setPhase(UpdateTransferPhase.failed);
          await tester.pumpAndSettle();
        }
        final label = inApp ? '浏览器下载' : '查看新版本';
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('正在打开…'), findsOneWidget);
        await tester.tap(find.text('正在打开…'));
        expect(repository.openReleaseCount, 1);
        gate.complete(
          const FailureResult(
            AppFailure(kind: FailureKind.platform, message: '无法打开浏览器'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);
      });
    }

    testWidgets('更新等待期间保持主题按钮颜色与禁用语义 dark=$dark', (tester) async {
      final repository = _FakeUpdateRepository(supported: true);
      await tester.pumpWidget(_Harness(repository: repository, dark: dark));
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey("update-primary-action"));
      Material surface() => tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first,
      );
      final before = surface().color;
      expect(before, Theme.of(tester.element(button)).colorScheme.primary);
      for (final phase in [
        UpdateTransferPhase.queued,
        UpdateTransferPhase.verifying,
        UpdateTransferPhase.awaitingPermission,
      ]) {
        repository.setPhase(phase);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(surface().color, before);
        expect(tester.widget<FilledButton>(button).onPressed, isNull);
      }
    });

    testWidgets('更新弹窗主按钮使用品牌色，次按钮使用中性表面 dark=$dark', (tester) async {
      final repository = _FakeUpdateRepository(supported: true);
      await tester.pumpWidget(
        _Harness(repository: repository, dark: dark, notes: '### 修复\n- 改善播放体验'),
      );
      final pageTheme = Theme.of(tester.element(find.text('show')));
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final context = tester.element(
        find.byKey(const ValueKey("update-primary-action")),
      );
      final theme = Theme.of(context);
      expect(theme.colorScheme, pageTheme.colorScheme);
      expect(theme.dialogTheme, pageTheme.dialogTheme);
      expect(dialog.backgroundColor, isNull);
      expect(dialog.shape, isNull);
      expect(
        theme.dialogTheme.backgroundColor,
        dark ? const Color(0xFF2C2C2C) : Colors.white,
      );
      expect(
        (theme.dialogTheme.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      expect(theme.colorScheme.primary, const Color(0xFF27AE60));
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('update-primary-action')),
      );
      expect(
        (button.style ?? theme.filledButtonTheme.style)!.foregroundColor!
            .resolve({}),
        theme.colorScheme.onPrimary,
      );
      final secondary = tester.widget<FilledButton>(
        find.byKey(const ValueKey('update-secondary-action')),
      );
      expect(
        secondary.style!.backgroundColor!.resolve({}),
        theme.colorScheme.surfaceContainerHighest,
      );
      expect(
        (theme.filledButtonTheme.style!.shape!.resolve({})!
                as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(8),
      );
      expect(Theme.of(tester.element(find.text('show'))), pageTheme);
      repository.setPhase(UpdateTransferPhase.downloading);
      await tester.pumpAndSettle();
      expect(
        Theme.of(
          tester.element(find.byType(LinearProgressIndicator)),
        ).progressIndicatorTheme.color,
        const Color(0xFF27AE60),
      );
    });
  }

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

  testWidgets('Android 一键更新，不展示内部线路或闲置下载面板', (tester) async {
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(_Harness(repository: repository));

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('立即更新'), findsOneWidget);
    expect(find.byType(DropdownButton<UpdateDownloadSource>), findsNothing);
    expect(find.text('下载线路'), findsNothing);
    expect(find.text('Android 安装包'), findsNothing);
    expect(find.text('浏览器下载'), findsNothing);

    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();

    expect(repository.downloadCount, 1);
  });

  testWidgets('长日志只使用一层滚动，底部操作无需滚动即可点击', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(
      _Harness(
        repository: repository,
        notes: List.filled(40, '- 优化播放体验。').join('\n'),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    expect(find.text('立即更新').hitTestable(), findsOneWidget);
    final close = find.byTooltip('关闭更新弹窗');
    expect(close.hitTestable(), findsOneWidget);
    final closeBefore = tester.getRect(close);
    final before = tester.getRect(find.text('立即更新'));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('立即更新')), before);
    expect(tester.getRect(close), closeBefore);
  });

  for (final layout in [
    (size: const Size(320, 568), scale: 1.0, dark: false),
    (size: const Size(375, 667), scale: 2.0, dark: true),
    (size: const Size(667, 375), scale: 2.0, dark: false),
    (size: const Size(568, 320), scale: 3.0, dark: true),
    (size: const Size(1024, 768), scale: 1.0, dark: true),
  ]) {
    testWidgets('所有更新阶段适配 ${layout.size} 字号 ${layout.scale}', (tester) async {
      tester.view.physicalSize = layout.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakeUpdateRepository(supported: true);
      await tester.pumpWidget(
        _Harness(
          repository: repository,
          notes: List.filled(40, '- 优化播放体验。').join('\n'),
          textScale: layout.scale,
          dark: layout.dark,
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      for (final phase in UpdateTransferPhase.values) {
        repository.setPhase(
          phase,
          error: phase == UpdateTransferPhase.paused ? '继续下载失败，请重试' : null,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull, reason: phase.name);
        final button = find.byKey(const ValueKey("update-primary-action"));
        final rect = tester.getRect(button);
        expect(rect.top, greaterThanOrEqualTo(0), reason: phase.name);
        expect(
          rect.bottom,
          lessThanOrEqualTo(layout.size.height - 24),
          reason: phase.name,
        );
        expect(button.hitTestable(), findsOneWidget, reason: phase.name);
        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(Scrollable),
          ),
          findsOneWidget,
        );
        final later = find.byTooltip('关闭更新弹窗');
        expect(later.hitTestable(), findsOneWidget, reason: phase.name);
        expect(
          tester.getRect(later).bottom,
          lessThanOrEqualTo(layout.size.height - 24),
          reason: phase.name,
        );
      }
    });
  }

  testWidgets('下载后仅展示进度，暂停继续和取消复用同一任务', (tester) async {
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(_Harness(repository: repository, notes: '更新说明'));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateTransferPanel), findsOneWidget);
    expect(find.text('更新内容'), findsNothing);
    expect(find.textContaining('加速'), findsNothing);
    expect(find.textContaining('GitHub'), findsNothing);
    expect(find.text('正在下载 50%'), findsOneWidget);
    await tester.tap(find.text('暂停下载'));
    await tester.pumpAndSettle();
    expect(repository.pauseCount, 1);
    expect(find.text('继续下载'), findsOneWidget);
    await tester.tap(find.text('继续下载'));
    await tester.pumpAndSettle();
    expect(repository.resumeCount, 1);
    expect(repository.downloadCount, 1);
    await tester.tap(find.text('取消下载'));
    await tester.pumpAndSettle();
    expect(repository.cancelCount, 1);
    expect(find.text('立即更新'), findsOneWidget);
    expect(find.text('更新内容'), findsOneWidget);
  });

  testWidgets('关闭弹窗不会取消后台下载，再打开恢复进度', (tester) async {
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(_Harness(repository: repository));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    repository.setPhase(UpdateTransferPhase.downloading);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭更新弹窗'));
    await tester.pumpAndSettle();
    expect(repository.cancelCount, 0);
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('正在下载 50%'), findsOneWidget);
    expect(repository.downloadCount, 0);
  });

  testWidgets('失败后可重试或通过浏览器下载，安装异常也有兜底', (tester) async {
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(_Harness(repository: repository));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    repository.setPhase(UpdateTransferPhase.failed, error: '下载失败，请重试');
    await tester.pumpAndSettle();
    expect(find.text('浏览器下载').hitTestable(), findsOneWidget);
    await tester.tap(find.text('重试下载'));
    await tester.pumpAndSettle();
    expect(repository.downloadCount, 1);
    repository.setPhase(UpdateTransferPhase.readyToInstall, error: '无法打开系统安装器');
    await tester.pumpAndSettle();
    expect(find.text('浏览器下载').hitTestable(), findsOneWidget);
    await tester.tap(find.text('浏览器下载'));
    await tester.pumpAndSettle();
    expect(repository.openReleaseCount, 1);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('下载初始化失败仍能使用浏览器，打开失败保持弹窗', (tester) async {
    final repository = _FakeUpdateRepository(supported: true)
      ..downloadResult = const FailureResult(
        AppFailure(kind: FailureKind.storage, message: '无法初始化更新下载'),
      )
      ..releaseResult = const FailureResult(
        AppFailure(kind: FailureKind.platform, message: '无法打开版本下载页面'),
      );
    await tester.pumpWidget(_Harness(repository: repository));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('立即更新'));
    await tester.pumpAndSettle();
    expect(find.text('浏览器下载').hitTestable(), findsOneWidget);
    await tester.tap(find.text('浏览器下载'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(repository.openReleaseCount, 1);
  });

  testWidgets('下载完成需用户点击安装，命令等待时不能重复触发', (tester) async {
    final pending = Completer<Result<void>>();
    final repository = _FakeUpdateRepository(supported: true)
      ..pendingDownload = pending;
    await tester.pumpWidget(_Harness(repository: repository));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('立即更新'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey("update-primary-action")),
          )
          .onPressed,
      isNull,
    );
    expect(repository.downloadCount, 1);
    await tester.pump(const Duration(milliseconds: 300));
    final loadingSurface = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey("update-primary-action")),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      loadingSurface.color,
      Theme.of(
        tester.element(find.byKey(const ValueKey('update-primary-action'))),
      ).colorScheme.primary,
    );
    pending.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    repository.setPhase(UpdateTransferPhase.readyToInstall);
    await tester.pumpAndSettle();
    expect(repository.installCount, 0);
    expect(find.textContaining('SHA-256'), findsNothing);
    await tester.tap(find.text('安装更新'));
    await tester.pumpAndSettle();
    expect(repository.installCount, 1);
    expect(find.text('再次安装'), findsOneWidget);
  });

  testWidgets('没有可信 APK 时回退浏览器，忽略只作用于当前版本', (tester) async {
    String? ignoredVersion;
    final repository = _FakeUpdateRepository(supported: true);
    await tester.pumpWidget(
      _Harness(
        repository: repository,
        hasAsset: false,
        onDismiss: (version) async => ignoredVersion = version,
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('查看新版本'), findsOneWidget);
    await tester.tap(find.text('忽略此版本'));
    await tester.pumpAndSettle();
    expect(ignoredVersion, '1.8.3');
    expect(find.byType(Dialog), findsNothing);
  });
}

final class _Harness extends StatelessWidget {
  const _Harness({
    required this.repository,
    this.notes = '',
    this.textScale = 1,
    this.dark = false,
    this.hasAsset = true,
    this.disableAnimations = true,
    this.onDismiss,
  });

  final UpdateRepository repository;
  final String notes;
  final double textScale;
  final bool dark;
  final bool hasAsset;
  final bool disableAnimations;
  final Future<void> Function(String)? onDismiss;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UpdateViewModel(repository: repository),
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => UpdateDialog.show(
                context,
                _version(notes: notes, hasAsset: hasAsset),
                onDismissVersion: onDismiss ?? (_) async {},
              ),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
  }
}

AppVersionInfo _version({String notes = '', bool hasAsset = true}) =>
    AppVersionInfo(
      currentVersion: '1.8.2',
      latestVersion: '1.8.3',
      releaseNotes: notes,
      releaseUri: Uri.parse(
        'https://github.com/coledaul/selene/releases/tag/v1.8.3',
      ),
      androidAsset: !hasAsset
          ? null
          : AppReleaseAsset(
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
  int downloadCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int cancelCount = 0;
  int installCount = 0;
  UpdateTransferState _transfer = const UpdateTransferState();
  Completer<Result<void>>? pendingDownload;
  Completer<Result<void>>? pendingRelease;
  Completer<Result<void>>? pendingPause;
  Completer<Result<void>>? pendingResume;
  Result<void> downloadResult = const Success<void>(null);
  Result<void> releaseResult = const Success<void>(null);
  Result<void> resumeResult = const Success<void>(null);

  void setPhase(UpdateTransferPhase phase, {String? error}) {
    _transfer = UpdateTransferState(
      phase: phase,
      version: '1.8.3',
      progress: 0.5,
      totalBytes: 66 * 1024 * 1024,
      downloadedBytes: 33 * 1024 * 1024,
      activeSource: UpdateDownloadSource.proxy,
      errorMessage: error,
    );
    notifyListeners();
  }

  @override
  Future<Result<void>> startDownload(AppVersionInfo versionInfo) async {
    downloadCount++;
    final result = pendingDownload != null
        ? await pendingDownload!.future
        : downloadResult;
    if (result.isSuccess) setPhase(UpdateTransferPhase.downloading);
    return result;
  }

  @override
  bool get supportsInAppDownload => _supported;

  @override
  UpdateTransferState get transfer => _transfer;

  @override
  Future<Result<void>> pause() async {
    pauseCount++;
    if (pendingPause != null) await pendingPause!.future;
    setPhase(UpdateTransferPhase.paused);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() async {
    resumeCount++;
    var result = resumeResult;
    if (pendingResume != null) {
      setPhase(UpdateTransferPhase.queued);
      result = await pendingResume!.future;
    }
    setPhase(
      result.isSuccess
          ? UpdateTransferPhase.downloading
          : UpdateTransferPhase.paused,
    );
    return result;
  }

  @override
  Future<Result<void>> cancel() async {
    cancelCount++;
    setPhase(UpdateTransferPhase.cancelled);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> install() async {
    installCount++;
    setPhase(UpdateTransferPhase.installerLaunched);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> openRelease(AppVersionInfo versionInfo) async {
    openReleaseCount++;
    if (pendingRelease != null) return pendingRelease!.future;
    return releaseResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
