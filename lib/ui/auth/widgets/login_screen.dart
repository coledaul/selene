import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/font_utils.dart';
import '../../../utils/device_utils.dart';
import '../../core/widgets/windows_title_bar.dart';
import '../view_models/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModelFactory});

  final LoginViewModel Function() viewModelFactory;

  static double contentMaxWidth({required bool isTablet}) =>
      isTablet ? 480 : 420;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _subscriptionUrlController;
  int _logoTapCount = 0;
  Timer? _tapTimer;
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModelFactory();
    final state = _viewModel.state;
    _urlController = TextEditingController(text: state.serverUrl);
    _usernameController = TextEditingController(text: state.username);
    _passwordController = TextEditingController(text: state.password);
    _subscriptionUrlController = TextEditingController(
      text: state.subscriptionUrl,
    );
    _viewModel.addListener(_syncControllers);
    unawaited(_viewModel.initialize());
  }

  void _syncControllers() {
    final state = _viewModel.state;
    _syncController(_urlController, state.serverUrl);
    _syncController(_usernameController, state.username);
    _syncController(_subscriptionUrlController, state.subscriptionUrl);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_syncControllers)
      ..dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _subscriptionUrlController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleLogoTap() {
    _logoTapCount++;
    _tapTimer?.cancel();
    if (_logoTapCount >= 10) {
      _logoTapCount = 0;
      _viewModel.toggleMode();
      _showMessage(
        _viewModel.state.localMode ? '已切换到本地模式' : '已切换到服务器模式',
        error: false,
      );
      return;
    }
    _tapTimer = Timer(const Duration(seconds: 1), () => _logoTapCount = 0);
  }

  Future<void> _handleServerLogin() async {
    if (_viewModel.busy ||
        !_viewModel.state.formValid ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final result = await _viewModel.login.execute();
    if (!mounted || result == null) {
      return;
    }
    if (result.isSuccess) {
      TextInput.finishAutofillContext(
        shouldSave: _viewModel.state.rememberLogin,
      );
    } else {
      _showMessage(result.failureOrNull!.message);
    }
  }

  Future<void> _handleLocalLogin() async {
    if (_viewModel.busy ||
        !_viewModel.state.formValid ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final prepared = await _viewModel.prepareLocalSubscription.execute();
    if (!mounted || prepared == null) {
      return;
    }
    final candidate = prepared.valueOrNull;
    if (candidate == null) {
      _showMessage(prepared.failureOrNull!.message);
      return;
    }
    if (candidate.replacesExistingData &&
        await _confirmReplaceLocalData() != true) {
      return;
    }
    final saved = await _viewModel.saveLocalSubscription.execute(candidate);
    if (!mounted || saved == null || saved.isSuccess) {
      return;
    }
    _showMessage(saved.failureOrNull!.message);
  }

  Future<bool?> _confirmReplaceLocalData() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('替换本地订阅'),
      content: const Text('订阅地址已改变，需要清空原有本地模式数据后重新导入。是否继续？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('继续'),
        ),
      ],
    ),
  );

  void _showMessage(String message, {bool error = true}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FontUtils.poppins(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: error
            ? const Color(0xFFe74c3c)
            : const Color(0xFF27ae60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        final isTablet = DeviceUtils.isTablet(context);
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFe6f3fb),
                  Color(0xFFeaf3f7),
                  Color(0xFFf7f7f3),
                  Color(0xFFe9ecef),
                  Color(0xFFdbe3ea),
                  Color(0xFFd3dde6),
                ],
                stops: [0, 0.18, 0.38, 0.60, 0.80, 1],
              ),
            ),
            child: Column(
              children: [
                if (Platform.isWindows) const WindowsTitleBar(forceBlack: true),
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          key: const Key('login-content-constraints'),
                          constraints: BoxConstraints(
                            maxWidth: LoginScreen.contentMaxWidth(
                              isTablet: isTablet,
                            ),
                          ),
                          child: _buildLoginContent(state.localMode),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginContent(bool localMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _handleLogoTap,
          child: Text(
            'Selene',
            style: FontUtils.sourceCodePro(
              fontSize: 42,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2c3e50),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: localMode
              ? _buildLocalModeForm()
              : AutofillGroup(child: _buildServerModeForm()),
        ),
      ],
    );
  }

  Widget _buildServerModeForm() {
    final state = _viewModel.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('server-url-field'),
          controller: _urlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.url],
          onChanged: _viewModel.updateServerUrl,
          decoration: _inputDecoration(
            label: '服务器地址',
            hint: 'https://example.com',
            icon: Icons.link,
          ),
          validator: _viewModel.validateServerUrl,
        ),
        if (state.usesInsecureHttp) ...[
          const SizedBox(height: 8),
          const Text(
            'HTTP 不会加密传输用户名和密码，仅建议在可信局域网中使用。',
            style: TextStyle(fontSize: 12, color: Color(0xFFc0392b)),
          ),
        ],
        const SizedBox(height: 20),
        TextFormField(
          key: const Key('username-field'),
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          onChanged: _viewModel.updateUsername,
          decoration: _inputDecoration(
            label: '用户名',
            hint: '请输入用户名',
            icon: Icons.person,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入用户名' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          key: const Key('password-field'),
          controller: _passwordController,
          obscureText: !state.passwordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: _viewModel.updatePassword,
          onFieldSubmitted: (_) => _handleServerLogin(),
          decoration:
              _inputDecoration(
                label: '密码',
                hint: '请输入密码',
                icon: Icons.lock,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: state.passwordVisible ? '隐藏密码' : '显示密码',
                  onPressed: _viewModel.togglePasswordVisibility,
                  icon: Icon(
                    state.passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xFF7f8c8d),
                    size: 20,
                  ),
                ),
              ),
          validator: (value) => value == null || value.isEmpty ? '请输入密码' : null,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          key: const Key('remember-login-checkbox'),
          value: state.rememberLogin,
          onChanged: _viewModel.busy
              ? null
              : (value) => _viewModel.setRememberLogin(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('记住登录'),
          subtitle: const Text('在此设备安全保存登录凭据，下次自动登录'),
        ),
        if (state.authMessage case final message? when message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFc0392b)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildLoginButton(_handleServerLogin),
      ],
    );
  }

  Widget _buildLocalModeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _subscriptionUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onChanged: _viewModel.updateSubscriptionUrl,
          onFieldSubmitted: (_) => _handleLocalLogin(),
          decoration: _inputDecoration(
            label: '订阅链接',
            hint: '请输入 HTTP(S) 订阅链接',
            icon: Icons.link,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入订阅链接' : null,
        ),
        const SizedBox(height: 32),
        _buildLoginButton(_handleLocalLogin),
      ],
    );
  }

  Widget _buildLoginButton(Future<void> Function() onPressed) {
    final enabled = _viewModel.state.formValid && !_viewModel.busy;
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xFF2c3e50)
            : const Color(0xFFbdc3c7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _viewModel.busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              '登录',
              style: FontUtils.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7f8c8d), size: 20),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
