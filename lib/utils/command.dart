import 'package:flutter/foundation.dart';

import 'result.dart';

typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  bool _disposed = false;
  int _operationGeneration = 0;
  Result<T>? _result;

  bool get running => _running;
  Result<T>? get result => _result;
  AppFailure? get failure => _result?.failureOrNull;

  Future<Result<T>?> run(Future<Result<T>> Function() action) async {
    if (_disposed || _running) {
      return null;
    }

    final generation = ++_operationGeneration;
    _running = true;
    _result = null;
    notifyListeners();
    late final Result<T> outcome;
    try {
      outcome = await action();
    } catch (error, stackTrace) {
      outcome = FailureResult<T>(
        AppFailure(
          kind: FailureKind.unknown,
          message: '操作执行失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
    if (!_disposed && generation == _operationGeneration) {
      _result = outcome;
      _running = false;
      notifyListeners();
    }
    return outcome;
  }

  void clearResult() {
    if (_disposed || _result == null) {
      return;
    }
    _result = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operationGeneration++;
    _running = false;
    super.dispose();
  }
}

final class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  Future<Result<T>?> execute() => run(_action);
}

final class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  Future<Result<T>?> execute(A argument) => run(() => _action(argument));
}
