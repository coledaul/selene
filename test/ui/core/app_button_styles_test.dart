import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/themes/app_theme.dart';
import 'package:selene/ui/core/themes/app_button_styles.dart';
import 'package:selene/ui/core/widgets/app_button_progress.dart';

void main() {
  for (final dark in [false, true]) {
    for (final elevated in [false, true]) {
      for (final custom in [false, true]) {
        testWidgets(
          '按钮状态遵循局部优先并区分禁用/加载 dark=$dark elevated=$elevated custom=$custom',
          (tester) async {
            final mode = ValueNotifier<int>(0);
            addTearDown(mode.dispose);
            var presses = 0;
            final theme = dark ? AppTheme.dark : AppTheme.light;
            const ownBackground = Color(0xFF2C3E50);
            const ownDisabled = Color(0xFFBDC3C7);
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: ValueListenableBuilder<int>(
                    valueListenable: mode,
                    builder: (context, state, _) {
                      final local = custom
                          ? FilledButton.styleFrom(
                              backgroundColor: ownBackground,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: ownDisabled,
                            )
                          : null;
                      final style = elevated
                          ? AppButtonStyles.elevated(
                              context,
                              loading: state == 2,
                              style: local,
                            )
                          : AppButtonStyles.filled(
                              context,
                              loading: state == 2,
                              style: local,
                            );
                      final child = state == 2
                          ? const AppButtonProgress(label: '正在处理')
                          : const Text('操作');
                      final VoidCallback? press = state == 0
                          ? () => presses++
                          : null;
                      return SizedBox(
                        width: 200,
                        child: elevated
                            ? ElevatedButton(
                                style: style,
                                onPressed: press,
                                child: child,
                              )
                            : FilledButton(
                                style: style,
                                onPressed: press,
                                child: child,
                              ),
                      );
                    },
                  ),
                ),
              ),
            );
            final button = find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            );
            Material surface() => tester.widget<Material>(
              find
                  .descendant(of: button, matching: find.byType(Material))
                  .first,
            );
            final background = custom
                ? ownBackground
                : theme.colorScheme.primary;
            expect(surface().color, background);
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(presses, 1);
            mode.value = 1;
            await tester.pumpAndSettle();
            expect(
              surface().color,
              custom
                  ? ownDisabled
                  : theme.filledButtonTheme.style!.backgroundColor!.resolve({
                      WidgetState.disabled,
                    }),
            );
            mode.value = 2;
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(surface().color, background);
            expect(
              tester
                  .widget<CircularProgressIndicator>(
                    find.byType(CircularProgressIndicator),
                  )
                  .color,
              Colors.white,
            );
            await tester.tap(button);
            await tester.pump();
            expect(presses, 1);
            mode.value = 0;
            await tester.pumpAndSettle();
            expect(surface().color, background);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
