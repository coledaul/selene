import 'package:flutter/foundation.dart';

/// UI ViewModel 的统一生命周期边界。
abstract class ViewModel extends ChangeNotifier {
  bool _disposed = false;

  @protected
  bool get isActive => !_disposed;

  /// 仅在 ViewModel 仍存活且状态真正变化时提交并通知监听器。
  @protected
  void updateState<T>(T current, T next, void Function(T value) commit) {
    if (_disposed || current == next) return;
    commit(next);
    notifyListeners();
  }

  /// 用于没有独立状态值的 Repository/Command 透传通知。
  @protected
  void notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
