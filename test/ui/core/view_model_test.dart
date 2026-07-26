import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/view_models/view_model.dart';

void main() {
  group('ViewModel lifecycle', () {
    test('active ViewModel commits changed state and notifies once', () {
      final viewModel = _TestViewModel();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setValue(1);
      viewModel.setValue(1);

      expect(viewModel.value, 1);
      expect(notifications, 1);
      viewModel.dispose();
    });

    test('disposed ViewModel ignores late state commits and notifications', () {
      final viewModel = _TestViewModel();
      viewModel.dispose();

      expect(() => viewModel.setValue(1), returnsNormally);
      expect(() => viewModel.notifyRepositoryChanged(), returnsNormally);
      expect(viewModel.value, 0);
    });

    test('disposed ViewModel still rejects new listeners', () {
      final viewModel = _TestViewModel();
      viewModel.dispose();

      expect(() => viewModel.addListener(() {}), throwsFlutterError);
    });
  });
}

final class _TestViewModel extends ViewModel {
  int value = 0;

  void setValue(int next) =>
      updateState(value, next, (newValue) => value = newValue);

  void notifyRepositoryChanged() => notifyIfActive();
}
