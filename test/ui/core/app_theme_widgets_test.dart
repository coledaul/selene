import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/themes/app_theme.dart';
import 'package:selene/ui/downloads/widgets/download_settings_dialog.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('原生按钮与弹窗继承同一全局主题 dark=$dark', (tester) async {
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const AlertDialog(
                        title: Text('标题'),
                        content: Text('正文'),
                      ),
                    ),
                    child: const Text('打开'),
                  ),
                  const FilledButton(onPressed: null, child: Text('不可用')),
                  const LinearProgressIndicator(value: .5),
                ],
              ),
            ),
          ),
        ),
      );
      final filled = find.byType(FilledButton).first;
      final material = tester.widget<Material>(
        find.descendant(of: filled, matching: find.byType(Material)).first,
      );
      expect(material.color, theme.colorScheme.primary);
      expect(tester.getSize(filled).height, greaterThanOrEqualTo(48));
      final disabled = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FilledButton).last,
              matching: find.byType(Material),
            )
            .first,
      );
      expect(disabled.color, isNot(material.color));
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.color, theme.dialogTheme.backgroundColor);
      expect(surface.shape, theme.dialogTheme.shape);
      expect(surface.surfaceTintColor, Colors.transparent);
      expect(
        Theme.of(tester.element(find.text('正文'))).colorScheme,
        theme.colorScheme,
      );
      expect(tester.takeException(), isNull);
    });

    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      testWidgets('下载设置在小屏与大字体下沿用共享主题 dark=$dark size=$size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = dark ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(body: DownloadSettingsDialog(currentValue: 2)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          Theme.of(
            tester.element(find.byType(AlertDialog)),
          ).colorScheme.primary,
          theme.colorScheme.primary,
        );
        expect(find.text('取消'), findsOneWidget);
      });
    }
  }
}
