import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:selene/routing/routes.dart';
import 'package:selene/ui/update/widgets/update_dialog.dart';
import 'package:selene/ui/settings/view_models/settings_view_model.dart';
import 'package:selene/utils/app_links.dart';
import 'package:selene/utils/device_utils.dart';
import 'package:selene/utils/font_utils.dart';
import 'package:selene/utils/result.dart';

class UserMenu extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onClose;
  final SettingsViewModel viewModel;

  const UserMenu({
    super.key,
    required this.isDarkMode,
    required this.viewModel,
    this.onClose,
  });

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  String get _username => widget.viewModel.state.username;
  String get _role => widget.viewModel.state.role;
  String get _doubanDataSource =>
      widget.viewModel.state.settings.doubanDataSource;
  String get _doubanImageSource =>
      widget.viewModel.state.settings.doubanImageSource;
  String get _m3u8ProxyUrl => widget.viewModel.state.settings.m3u8ProxyUrl;
  String get _version => widget.viewModel.state.settings.appVersion;
  bool get _preferSpeedTest => widget.viewModel.state.settings.preferSpeedTest;
  bool get _localSearch => widget.viewModel.state.settings.localSearch;
  bool get _isLocalMode => widget.viewModel.state.localMode;

  @override
  void initState() {
    super.initState();
    widget.viewModel
      ..addListener(_handleViewModelChanged)
      ..initialize();
  }

  void _handleViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleViewModelChanged);
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await widget.viewModel.logout.execute();
  }

  Future<void> _handleClearDoubanCache() async {
    final result = await widget.viewModel.clearCaches.execute();
    if (mounted) {
      if (result is Success<void>) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已清除豆瓣缓存')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('清除豆瓣缓存失败')));
      }
      widget.onClose?.call();
    }
  }

  Future<void> _handleCheckUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '正在检查更新...',
          style: FontUtils.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 2),
      ),
    );
    final result = await widget.viewModel.checkUpdate.execute();
    if (!mounted) {
      return;
    }
    if (result case FailureResult(:final failure)) {
      _showMessage(failure.message, error: true);
      return;
    }
    final versionInfo = result?.valueOrNull;
    if (versionInfo == null) {
      _showMessage('当前已是最新版本');
      return;
    }
    widget.viewModel.consumeAvailableUpdate();
    await UpdateDialog.show(
      context,
      versionInfo,
      onDismissVersion: (version) async {
        await widget.viewModel.dismissUpdate.execute(version);
      },
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FontUtils.poppins(color: Colors.white)),
        backgroundColor: error
            ? const Color(0xFFEF4444)
            : const Color(0xFF27AE60),
      ),
    );
  }

  void _openDownloadManager() {
    const DownloadsRoute().push<void>(context);
    widget.onClose?.call();
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Selene',
      applicationVersion: _version.isEmpty ? null : _version,
    );
    widget.onClose?.call();
  }

  Widget _buildRoleTag() {
    String label;
    Color color;

    switch (_role) {
      case 'admin':
        label = '管理员';
        color = const Color(0xFFf59e0b); // 橙黄色
        break;
      case 'owner':
        label = '站长';
        color = const Color(0xFF8b5cf6); // 紫色
        break;
      case 'user':
      default:
        label = '用户';
        color = const Color(0xFF10b981); // 绿色
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: FontUtils.poppins(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOptionSelector({
    required String title,
    required String currentValue,
    required List<String> options,
    required Future<void> Function(String) onChanged,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showOptionDialog(title, currentValue, options, onChanged),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: widget.isDarkMode
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: widget.isDarkMode
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentValue,
                      style: FontUtils.poppins(
                        fontSize: 12,
                        color: widget.isDarkMode
                            ? const Color(0xFF9ca3af)
                            : const Color(0xFF6b7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: widget.isDarkMode
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionDialog(
    String title,
    String currentValue,
    List<String> options,
    Future<void> Function(String) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode
              ? const Color(0xFF2c2c2c)
              : Colors.white,
          title: Text(
            title,
            style: FontUtils.poppins(
              fontSize: 18,
              color: widget.isDarkMode
                  ? const Color(0xFFffffff)
                  : const Color(0xFF1f2937),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await onChanged(option);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentValue == option
                              ? LucideIcons.check
                              : LucideIcons.circle,
                          size: 20,
                          color: currentValue == option
                              ? const Color(0xFF10b981)
                              : (widget.isDarkMode
                                    ? const Color(0xFF9ca3af)
                                    : const Color(0xFF6b7280)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: FontUtils.poppins(
                              fontSize: 16,
                              color: widget.isDarkMode
                                  ? const Color(0xFFffffff)
                                  : const Color(0xFF1f2937),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showM3u8ProxyUrlDialog() {
    final controller = TextEditingController(text: _m3u8ProxyUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode
              ? const Color(0xFF2c2c2c)
              : Colors.white,
          title: Text(
            'M3U8 代理 URL',
            style: FontUtils.poppins(
              fontSize: 18,
              color: widget.isDarkMode
                  ? const Color(0xFFffffff)
                  : const Color(0xFF1f2937),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            style: FontUtils.poppins(
              fontSize: 14,
              color: widget.isDarkMode
                  ? const Color(0xFFffffff)
                  : const Color(0xFF1f2937),
            ),
            decoration: InputDecoration(
              hintText: '输入代理 URL（可选）',
              hintStyle: FontUtils.poppins(
                fontSize: 14,
                color: widget.isDarkMode
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFe5e7eb),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFe5e7eb),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF10b981),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: widget.isDarkMode
                      ? const Color(0xFF9ca3af)
                      : const Color(0xFF6b7280),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final url = controller.text.trim();
                final result = await widget.viewModel.saveM3u8ProxyUrl(url);
                if (!mounted) return;
                if (result case FailureResult(:final failure)) {
                  _showMessage(failure.message, error: true);
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                '保存',
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: const Color(0xFF10b981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Widget _buildInputOption({
    required String title,
    required String currentValue,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: widget.isDarkMode
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: widget.isDarkMode
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentValue.isEmpty ? '未设置' : currentValue,
                      style: FontUtils.poppins(
                        fontSize: 12,
                        color: widget.isDarkMode
                            ? const Color(0xFF9ca3af)
                            : const Color(0xFF6b7280),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: widget.isDarkMode
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool value,
    required Future<void> Function(bool) onChanged,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: widget.isDarkMode
                  ? const Color(0xFF9ca3af)
                  : const Color(0xFF6b7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: FontUtils.poppins(
                  fontSize: 16,
                  color: widget.isDarkMode
                      ? const Color(0xFFffffff)
                      : const Color(0xFF1f2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await onChanged(!value);
                if (!mounted) return;
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: value
                      ? const Color(0xFF10b981)
                      : (widget.isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb)),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击菜单内容时关闭
              child: Container(
                width: 280,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height - 40,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF2c2c2c)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    // 用户信息区域
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 本地模式下不显示"当前模式"标签
                          if (!_isLocalMode)
                            Text(
                              '当前用户',
                              style: FontUtils.poppins(
                                fontSize: 12,
                                color: widget.isDarkMode
                                    ? const Color(0xFF9ca3af)
                                    : const Color(0xFF6b7280),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          if (!_isLocalMode) const SizedBox(height: 8),
                          // 用户名或本地模式
                          if (_isLocalMode)
                            Text(
                              '本地模式',
                              style: FontUtils.poppins(
                                fontSize: 18,
                                color: widget.isDarkMode
                                    ? const Color(0xFFffffff)
                                    : const Color(0xFF1f2937),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _username.isEmpty ? '未知用户' : _username,
                                  style: FontUtils.poppins(
                                    fontSize: 18,
                                    color: widget.isDarkMode
                                        ? const Color(0xFFffffff)
                                        : const Color(0xFF1f2937),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 角色标签
                                _buildRoleTag(),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 豆瓣数据源选项
                    _buildOptionSelector(
                      title: '豆瓣数据源',
                      currentValue: _doubanDataSource,
                      options: const [
                        '直连',
                        'Cors Proxy By Zwei',
                        '豆瓣 CDN By CMLiussss（腾讯云）',
                        '豆瓣 CDN By CMLiussss（阿里云）',
                      ],
                      onChanged: (value) async {
                        final result = await widget.viewModel
                            .saveDoubanDataSource(value);
                        if (mounted && result.isFailure) {
                          _showMessage(
                            result.failureOrNull!.message,
                            error: true,
                          );
                        }
                      },
                      icon: LucideIcons.database,
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 豆瓣图片源选项
                    _buildOptionSelector(
                      title: '豆瓣图片源',
                      currentValue: _doubanImageSource,
                      options: const [
                        '直连',
                        '豆瓣官方精品 CDN',
                        '豆瓣 CDN By CMLiussss（腾讯云）',
                        '豆瓣 CDN By CMLiussss（阿里云）',
                      ],
                      onChanged: (value) async {
                        final result = await widget.viewModel
                            .saveDoubanImageSource(value);
                        if (mounted && result.isFailure) {
                          _showMessage(
                            result.failureOrNull!.message,
                            error: true,
                          );
                        }
                      },
                      icon: LucideIcons.image,
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // M3U8 代理 URL 选项
                    _buildInputOption(
                      title: 'M3U8 代理 URL',
                      currentValue: _m3u8ProxyUrl,
                      onTap: _showM3u8ProxyUrlDialog,
                      icon: LucideIcons.link,
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 优选测速选项
                    _buildToggleOption(
                      title: '优选测速',
                      value: _preferSpeedTest,
                      onChanged: (value) async {
                        final result = await widget.viewModel
                            .savePreferSpeedTest(value);
                        if (mounted && result.isFailure) {
                          _showMessage(
                            result.failureOrNull!.message,
                            error: true,
                          );
                        }
                      },
                      icon: LucideIcons.zap,
                    ),
                    // 本地搜索选项（本地模式下不显示）
                    if (!_isLocalMode) ...[
                      // 分割线
                      Container(
                        height: 1,
                        color: widget.isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                      _buildToggleOption(
                        title: '本地搜索',
                        value: _localSearch,
                        onChanged: (value) async {
                          final result = await widget.viewModel.saveLocalSearch(
                            value,
                          );
                          if (mounted && result.isFailure) {
                            _showMessage(
                              result.failureOrNull!.message,
                              error: true,
                            );
                          }
                        },
                        icon: LucideIcons.search,
                      ),
                    ],
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 下载管理入口
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openDownloadManager,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.download,
                                size: 20,
                                color: Color(0xFF10b981),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '下载管理',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  color: widget.isDarkMode
                                      ? const Color(0xFFffffff)
                                      : const Color(0xFF1f2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 清除豆瓣缓存按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleClearDoubanCache,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                size: 20,
                                color: const Color(0xFFf59e0b),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '清除豆瓣缓存',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  color: widget.isDarkMode
                                      ? const Color(0xFFffffff)
                                      : const Color(0xFF1f2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 检查更新按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleCheckUpdate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.download,
                                size: 20,
                                color: const Color(0xFF3b82f6),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '检查更新',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  color: widget.isDarkMode
                                      ? const Color(0xFFffffff)
                                      : const Color(0xFF1f2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 开源许可
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openLicenses,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.balance_outlined,
                                size: 20,
                                color: Color(0xFF8b5cf6),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '开源许可',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  color: widget.isDarkMode
                                      ? const Color(0xFFffffff)
                                      : const Color(0xFF1f2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 登出按钮
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleLogout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.logOut,
                                size: 20,
                                color: Color(0xFFef4444),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '登出',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFFef4444),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    // 版本号
                    MouseRegion(
                      cursor: DeviceUtils.isPC()
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      child: GestureDetector(
                        onTap: () async {
                          final url = AppLinks.repositoryUri;
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Center(
                            child: Text(
                              _version.isEmpty ? 'v1.4.3' : 'v$_version',
                              style: FontUtils.poppins(
                                fontSize: 14,
                                color: widget.isDarkMode
                                    ? const Color(0xFF9ca3af)
                                    : const Color(0xFF6b7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
