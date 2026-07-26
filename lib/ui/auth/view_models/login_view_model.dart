import 'dart:async';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../domain/models/auth_models.dart';
import '../../../domain/models/subscription.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import '../../core/view_models/view_model.dart';
import 'login_ui_state.dart';

class LoginViewModel extends ViewModel {
  LoginViewModel({
    required AuthRepository authRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _authRepository = authRepository,
       _subscriptionRepository = subscriptionRepository,
       _state = LoginUiState(
         serverUrl: authRepository.profile.serverUrl,
         username: authRepository.profile.username,
         rememberLogin: authRepository.profile.rememberLogin,
         authMessage: authRepository.message,
       ) {
    login = Command0<void>(_login)..addListener(_notifyCommandChanged);
    prepareLocalSubscription = Command0<SubscriptionCandidate>(_prepareLocal)
      ..addListener(_notifyCommandChanged);
    saveLocalSubscription = Command1<void, SubscriptionCandidate>(_saveLocal)
      ..addListener(_notifyCommandChanged);
    _authRepository.addListener(_syncAuthState);
  }

  final AuthRepository _authRepository;
  final SubscriptionRepository _subscriptionRepository;
  LoginUiState _state;

  late final Command0<void> login;
  late final Command0<SubscriptionCandidate> prepareLocalSubscription;
  late final Command1<void, SubscriptionCandidate> saveLocalSubscription;

  LoginUiState get state => _state;
  bool get busy =>
      login.running ||
      prepareLocalSubscription.running ||
      saveLocalSubscription.running;

  Future<void> initialize() async {
    final subscriptionUrl = await _subscriptionRepository.loadUrl();
    _setState(_state.copyWith(subscriptionUrl: subscriptionUrl));
  }

  void updateServerUrl(String value) =>
      _setState(_state.copyWith(serverUrl: value));
  void updateUsername(String value) =>
      _setState(_state.copyWith(username: value));
  void updatePassword(String value) =>
      _setState(_state.copyWith(password: value));
  void updateSubscriptionUrl(String value) =>
      _setState(_state.copyWith(subscriptionUrl: value));
  void setRememberLogin(bool value) =>
      _setState(_state.copyWith(rememberLogin: value));
  void toggleMode() => _setState(_state.copyWith(localMode: !_state.localMode));
  void togglePasswordVisibility() =>
      _setState(_state.copyWith(passwordVisible: !_state.passwordVisible));

  String? validateServerUrl(String? value) {
    try {
      AuthProfile.normalizeServerUrl(value ?? '');
      return null;
    } on FormatException catch (error) {
      return error.message;
    }
  }

  Future<Result<void>> _login() async {
    if (!_state.formValid) {
      return const FailureResult(
        AppFailure(kind: FailureKind.validation, message: '请完整填写登录信息'),
      );
    }
    final result = await _authRepository.login(
      serverUrl: _state.serverUrl,
      username: _state.username,
      password: _state.password,
      rememberLogin: _state.rememberLogin,
    );
    return result.isSuccess
        ? const Success<void>(null)
        : FailureResult(
            AppFailure(
              kind: _mapLoginFailure(result.failure),
              message: result.message ?? '登录失败',
            ),
          );
  }

  Future<Result<SubscriptionCandidate>> _prepareLocal() {
    return _subscriptionRepository.prepare(_state.subscriptionUrl);
  }

  Future<Result<void>> _saveLocal(SubscriptionCandidate candidate) async {
    final saved = await _subscriptionRepository.save(candidate);
    if (saved.isFailure) {
      return saved;
    }
    try {
      await _authRepository.enterLocalMode();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: '无法进入本地模式',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  FailureKind _mapLoginFailure(AuthLoginFailure failure) => switch (failure) {
    AuthLoginFailure.invalidCredentials => FailureKind.authentication,
    AuthLoginFailure.invalidServer => FailureKind.validation,
    AuthLoginFailure.network => FailureKind.network,
    AuthLoginFailure.protocol => FailureKind.protocol,
    AuthLoginFailure.secureStorage => FailureKind.storage,
    AuthLoginFailure.none || AuthLoginFailure.unknown => FailureKind.unknown,
  };

  void _syncAuthState() {
    final profile = _authRepository.profile;
    _setState(
      _state.copyWith(
        serverUrl: profile.serverUrl,
        username: profile.username,
        rememberLogin: profile.rememberLogin,
        authMessage: _authRepository.message,
      ),
    );
  }

  void _notifyCommandChanged() => notifyIfActive();

  void _setState(LoginUiState value) =>
      updateState(_state, value, (next) => _state = next);

  @override
  void dispose() {
    _authRepository.removeListener(_syncAuthState);
    login
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    prepareLocalSubscription
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    saveLocalSubscription
      ..removeListener(_notifyCommandChanged)
      ..dispose();
    super.dispose();
  }
}
