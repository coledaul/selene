import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/auth_repository.dart';
import 'package:selene/data/repositories/subscription_repository.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/domain/models/subscription.dart';
import 'package:selene/ui/auth/view_models/login_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('服务器表单状态与登录命令完全由 ViewModel 管理', () async {
    final auth = _FakeAuthRepository();
    final viewModel = LoginViewModel(
      authRepository: auth,
      subscriptionRepository: _FakeSubscriptionRepository(),
    );

    viewModel
      ..updateServerUrl('https://example.com')
      ..updateUsername('alice')
      ..updatePassword('secret')
      ..setRememberLogin(true);
    final result = await viewModel.login.execute();

    expect(result?.isSuccess, isTrue);
    expect(auth.lastUsername, 'alice');
    expect(auth.lastRememberLogin, isTrue);
    viewModel.dispose();
  });

  test('本地订阅先准备候选，再保存并进入本地模式', () async {
    final auth = _FakeAuthRepository();
    final subscriptions = _FakeSubscriptionRepository();
    final viewModel = LoginViewModel(
      authRepository: auth,
      subscriptionRepository: subscriptions,
    )..updateSubscriptionUrl('https://example.com/subscription');

    final prepared = await viewModel.prepareLocalSubscription.execute();
    final candidate = prepared?.valueOrNull;
    expect(candidate, isNotNull);

    final saved = await viewModel.saveLocalSubscription.execute(candidate!);

    expect(saved?.isSuccess, isTrue);
    expect(subscriptions.saved, same(candidate));
    expect(auth.status, AuthStatus.localMode);
    viewModel.dispose();
  });

  test('初始化期间销毁后完成结果不会写入已销毁 ViewModel', () async {
    final subscriptions = _ControlledSubscriptionRepository();
    final viewModel = LoginViewModel(
      authRepository: _FakeAuthRepository(),
      subscriptionRepository: subscriptions,
    );

    final loading = viewModel.initialize();
    viewModel.dispose();
    subscriptions.complete('https://example.com/subscription');

    await expectLater(loading, completes);
    expect(viewModel.state.subscriptionUrl, isEmpty);
  });
}

final class _ControlledSubscriptionRepository
    extends _FakeSubscriptionRepository {
  final _url = Completer<String>();

  void complete(String value) => _url.complete(value);

  @override
  Future<String> loadUrl() => _url.future;
}

class _FakeAuthRepository extends ChangeNotifier implements AuthRepository {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? lastUsername;
  bool? lastRememberLogin;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  @override
  String? get message => null;

  @override
  AuthProfile get profile => const AuthProfile();

  @override
  String get role => 'user';

  @override
  AuthStatus get status => _status;

  @override
  void clearMessage() {}

  @override
  Future<void> enterLocalMode() async {
    _status = AuthStatus.localMode;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> invalidateSession({String? message}) async {}

  @override
  Future<void> leaveLocalMode() async {}

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
    required bool rememberLogin,
  }) async {
    lastUsername = username;
    lastRememberLogin = rememberLogin;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return const AuthLoginResult.success();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> reauthenticate() async => true;
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionCandidate? saved;

  @override
  Future<String> loadUrl() async => '';

  @override
  Future<Result<SubscriptionCandidate>> prepare(String url) async {
    return Success(
      SubscriptionCandidate(
        url: url,
        searchSources: const [],
        liveSources: const [],
        replacesExistingData: false,
      ),
    );
  }

  @override
  Future<Result<void>> refresh() async => const Success<void>(null);

  @override
  Future<Result<void>> save(SubscriptionCandidate candidate) async {
    saved = candidate;
    return const Success<void>(null);
  }

  @override
  void dispose() {}
}
