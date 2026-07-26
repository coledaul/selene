import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/utils/command.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('Command0', () {
    test('执行期间阻止重复运行并公开最终结果', () async {
      final completer = Completer<Result<int>>();
      var calls = 0;
      final command = Command0<int>(() {
        calls++;
        return completer.future;
      });

      final first = command.execute();
      final duplicate = await command.execute();

      expect(command.running, isTrue);
      expect(calls, 1);
      expect(duplicate, isNull);

      completer.complete(const Success<int>(7));
      final result = await first;

      expect(result?.valueOrNull, 7);
      expect(command.running, isFalse);
      expect(command.result?.valueOrNull, 7);
    });

    test('未处理异常被收敛为 unknown failure', () async {
      final command = Command0<void>(() async => throw StateError('boom'));

      final result = await command.execute();

      expect(result?.failureOrNull?.kind, FailureKind.unknown);
      expect(result?.failureOrNull?.cause, isA<StateError>());
    });

    test('clearResult 只清理一次性结果', () async {
      final command = Command0<int>(() async => const Success<int>(1));
      await command.execute();

      command.clearResult();

      expect(command.result, isNull);
      expect(command.running, isFalse);
    });

    test('执行期间销毁后异步完成不会通知已销毁对象', () async {
      final completer = Completer<Result<int>>();
      final command = Command0<int>(() => completer.future);

      final running = command.execute();
      command.dispose();
      completer.complete(const Success<int>(7));

      final result = await running;
      expect(result?.valueOrNull, 7);
    });
  });

  test('Command1 将强类型参数传给动作', () async {
    final command = Command1<String, int>(
      (value) async => Success<String>('episode-$value'),
    );

    final result = await command.execute(3);

    expect(result?.valueOrNull, 'episode-3');
  });
}
