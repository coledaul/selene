import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../features/auth/application/auth_session_controller.dart';
import '../features/auth/domain/auth_models.dart';
import '../services/local_mode_storage_service.dart';
import '../services/subscription_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../widgets/windows_title_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subscriptionUrlController = TextEditingController();

  bool _profileLoaded = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isLocalMode = false;
  bool _rememberLogin = false;
  int _logoTapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    for (final controller in <TextEditingController>[
      _urlController,
      _usernameController,
      _passwordController,
      _subscriptionUrlController,
    ]) {
      controller.addListener(_validateForm);
    }
    unawaited(_loadSubscriptionUrl());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoaded) {
      return;
    }
    _profileLoaded = true;
    final profile = context.read<AuthSessionController>().profile;
    _urlController.text = profile.serverUrl;
    _usernameController.text = profile.username;
    _rememberLogin = profile.rememberLogin;
    _validateForm();
  }

  Future<void> _loadSubscriptionUrl() async {
    final value = await LocalModeStorageService.getSubscriptionUrl();
    if (!mounted || value == null || value.isEmpty) {
      return;
    }
    _subscriptionUrlController.text = value;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _subscriptionUrlController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  void _validateForm() {
    if (!mounted) {
      return;
    }
    final valid = _isLocalMode
        ? _subscriptionUrlController.text.trim().isNotEmpty
        : _urlController.text.trim().isNotEmpty &&
            _usernameController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty;
    if (_isFormValid != valid) {
      setState(() => _isFormValid = valid);
    } else if (!_isLocalMode) {
      setState(() {});
    }
  }

  void _handleLogoTap() {
    _logoTapCount++;
    _tapTimer?.cancel();
    if (_logoTapCount >= 10) {
      setState(() {
        _logoTapCount = 0;
        _isLocalMode = !_isLocalMode;
      });
      _validateForm();
      _showToast(
        _isLocalMode ? '已切换到本地模式' : '已切换到服务器模式',
        const Color(0xFF27ae60),
      );
      return;
    }
    _tapTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        _logoTapCount = 0;
      }
    });
  }

  Future<void> _handleServerLogin() async {
    if (_isLoading ||
        !_isFormValid ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isLoading = true);
    final result = await context.read<AuthSessionController>().login(
          serverUrl: _urlController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          rememberLogin: _rememberLogin,
        );
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (result.isSuccess) {
      TextInput.finishAutofillContext(shouldSave: _rememberLogin);
    }
  }

  Future<void> _handleLocalModeLogin() async {
    if (_isLoading ||
        !_isFormValid ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final newUrl = _subscriptionUrlController.text.trim();
      final uri = Uri.tryParse(newUrl);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        throw const FormatException('请输入有效的 HTTP(S) 订阅地址');
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('获取订阅内容失败（HTTP ${response.statusCode}）');
      }
      final content =
          await SubscriptionService.parseSubscriptionContent(response.body);
      final hasSearchSources = content?.searchResources?.isNotEmpty ?? false;
      final hasLiveSources = content?.liveSources?.isNotEmpty ?? false;
      if (content == null || (!hasSearchSources && !hasLiveSources)) {
        throw const FormatException('订阅内容格式无效');
      }
      if (!mounted) {
        return;
      }

      final existingUrl = await LocalModeStorageService.getSubscriptionUrl();
      if (!mounted) {
        return;
      }
      if (existingUrl != null &&
          existingUrl.isNotEmpty &&
          existingUrl != newUrl) {
        setState(() => _isLoading = false);
        final shouldClear = await _confirmReplaceLocalData();
        if (shouldClear != true || !mounted) {
          return;
        }
        setState(() => _isLoading = true);
        await LocalModeStorageService.clearAllLocalModeData();
      }

      await LocalModeStorageService.saveSubscriptionUrl(newUrl);
      if (hasSearchSources) {
        await LocalModeStorageService.saveSearchSources(
          content.searchResources!,
        );
      }
      if (hasLiveSources) {
        await LocalModeStorageService.saveLiveSources(content.liveSources!);
      }
      if (!mounted) {
        return;
      }
      await context.read<AuthSessionController>().enterLocalMode();
    } on TimeoutException {
      _showToast('订阅请求超时', const Color(0xFFe74c3c));
    } catch (error) {
      _showToast(_safeErrorMessage(error), const Color(0xFFe74c3c));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _confirmReplaceLocalData() {
    return showDialog<bool>(
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
  }

  String _safeErrorMessage(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return '本地模式登录失败，请检查订阅地址和网络';
  }

  void _showToast(String message, Color backgroundColor) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FontUtils.poppins(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 480 : 420,
                      ),
                      child: _buildLoginContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
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
          child: _isLocalMode
              ? _buildLocalModeForm()
              : AutofillGroup(child: _buildServerModeForm()),
        ),
      ],
    );
  }

  Widget _buildServerModeForm() {
    final insecureHttp = _urlController.text.trim().startsWith('http://');
    final authMessage = context.select<AuthSessionController, String?>(
      (controller) => controller.message,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('server-url-field'),
          controller: _urlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.url],
          decoration: _inputDecoration(
            label: '服务器地址',
            hint: 'https://example.com',
            icon: Icons.link,
          ),
          validator: (value) {
            try {
              AuthProfile.normalizeServerUrl(value ?? '');
              return null;
            } on FormatException catch (error) {
              return error.message;
            }
          },
        ),
        if (insecureHttp) ...[
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
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _handleServerLogin(),
          decoration: _inputDecoration(
            label: '密码',
            hint: '请输入密码',
            icon: Icons.lock,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip: _isPasswordVisible ? '隐藏密码' : '显示密码',
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
          value: _rememberLogin,
          onChanged: _isLoading
              ? null
              : (value) => setState(() => _rememberLogin = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('记住登录'),
          subtitle: const Text('在此设备安全保存登录凭据，下次自动登录'),
        ),
        if (authMessage != null && authMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              authMessage,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFc0392b),
              ),
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
          onFieldSubmitted: (_) => _handleLocalModeLogin(),
          decoration: _inputDecoration(
            label: '订阅链接',
            hint: '请输入 HTTP(S) 订阅链接',
            icon: Icons.link,
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入订阅链接' : null,
        ),
        const SizedBox(height: 32),
        _buildLoginButton(_handleLocalModeLogin),
      ],
    );
  }

  Widget _buildLoginButton(Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: _isLoading || !_isFormValid ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFormValid && !_isLoading
            ? const Color(0xFF2c3e50)
            : const Color(0xFFbdc3c7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isLoading
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
