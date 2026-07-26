import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_ui_state.freezed.dart';

@freezed
abstract class LoginUiState with _$LoginUiState {
  const LoginUiState._();

  const factory LoginUiState({
    @Default('') String serverUrl,
    @Default('') String username,
    @Default('') String password,
    @Default('') String subscriptionUrl,
    @Default(false) bool rememberLogin,
    @Default(false) bool localMode,
    @Default(false) bool passwordVisible,
    String? authMessage,
  }) = _LoginUiState;

  bool get formValid => localMode
      ? subscriptionUrl.trim().isNotEmpty
      : serverUrl.trim().isNotEmpty &&
            username.trim().isNotEmpty &&
            password.isNotEmpty;

  bool get usesInsecureHttp => serverUrl.trim().startsWith('http://');
}
