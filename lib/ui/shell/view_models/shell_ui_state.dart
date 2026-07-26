import 'package:freezed_annotation/freezed_annotation.dart';

part 'shell_ui_state.freezed.dart';

@freezed
abstract class ShellUiState with _$ShellUiState {
  const factory ShellUiState({
    @Default('') String query,
    @Default(<String>[]) List<String> suggestions,
    @Default(false) bool loadingSuggestions,
  }) = _ShellUiState;
}
