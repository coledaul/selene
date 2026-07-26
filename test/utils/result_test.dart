import 'package:flutter_test/flutter_test.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('Result', () {
    test('Success 暴露值且不会伪装为失败', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('FailureResult 保留类型化错误与原始原因', () {
      final cause = StateError('socket closed');
      final failure = AppFailure(
        kind: FailureKind.network,
        message: '网络请求失败',
        cause: cause,
      );
      final result = FailureResult<int>(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.failureOrNull?.cause, same(cause));
    });
  });
}
