import 'package:flutter/material.dart';
import 'package:selene/domain/models/live_channel.dart';
import 'package:selene/domain/models/live_source.dart';
import 'package:selene/ui/core/view_models/theme_view_model.dart';
import 'package:selene/ui/core/widgets/filter_options_selector.dart';
import 'package:selene/ui/core/widgets/filter_pill_hover.dart';
import 'package:selene/ui/live/view_models/live_player_view_model.dart';
import 'package:selene/ui/live/view_models/live_ui_state.dart';
import 'package:selene/ui/live/view_models/live_view_model.dart';
import 'package:selene/ui/player/view_models/dlna_cast_view_model.dart';
import 'package:selene/utils/device_utils.dart';
import 'package:selene/utils/font_utils.dart';
import 'package:provider/provider.dart';
import 'live_player_screen.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({
    super.key,
    required this.viewModel,
    required this.playerViewModelFactory,
    required this.dlnaCastViewModelFactory,
  });

  /// 由首页作用域持有生命周期，本页面只订阅状态。
  final LiveViewModel viewModel;
  final LivePlayerViewModel Function(LiveChannel channel, LiveSource source)
  playerViewModelFactory;
  final DlnaCastViewModel Function() dlnaCastViewModelFactory;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen>
    with SingleTickerProviderStateMixin {
  LiveUiState get _state => widget.viewModel.state;
  List<LiveChannelGroup> get _channelGroups => _state.groups;
  List<LiveSource> get _liveSources => _state.sources;
  LiveSource? get _currentSource => _state.currentSource;
  bool get _isLoading => _state.loading;
  bool get _isRefreshing => _state.refreshing;
  bool get _isInitialLoad => _state.initialLoad;
  String? get _errorMessage => _state.error;
  String get _selectedGroup => _state.selectedGroup;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _refreshIconController;
  bool _isRefreshButtonHovered = false;

  @override
  void initState() {
    super.initState();
    _refreshIconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    widget.viewModel
      ..addListener(_handleViewModelChanged)
      ..initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshIconController.dispose();
    widget.viewModel.removeListener(_handleViewModelChanged);
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    final notice = _state.notice;
    setState(() {});
    if (notice != null) {
      widget.viewModel.consumeNotice();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(notice);
      });
    }
  }

  void _scrollToTop() {
    if (!mounted) return;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadChannels({LiveSource? source}) async {
    if (source == null) {
      await widget.viewModel.initialize();
    } else {
      await widget.viewModel.selectSource(source);
    }
  }

  Future<void> refreshChannels() async {
    if (!mounted) return;
    setState(() => _isRefreshButtonHovered = false);
    _refreshIconController.repeat();
    final result = await widget.viewModel.refresh();
    if (!mounted) return;
    _refreshIconController
      ..stop()
      ..reset();
    if (result.isFailure) {
      _showMessage(result.failureOrNull!.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FontUtils.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF3498DB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<LiveChannel> _getFilteredChannels() => _state.filteredChannels;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeService, child) {
        return Column(
          children: [
            _buildTopBar(themeService),
            Expanded(
              child: _isRefreshing
                  ? _buildRefreshingView(themeService)
                  : _isLoading
                  ? _buildLoadingView(themeService)
                  : _errorMessage != null
                  ? _buildErrorView(themeService)
                  : _buildChannelList(themeService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(ThemeViewModel themeService) {
    final allGroups = ['全部', ..._channelGroups.map((g) => g.name)];

    // 构建分组选项
    final groupOptions = allGroups
        .map((g) => SelectorOption(label: g, value: g))
        .toList();

    // 构建直播源选项
    final sourceOptions = _liveSources
        .map((s) => SelectorOption(label: s.name, value: s.key))
        .toList();

    // 判断是否只有一个直播源
    final showSourceFilter = _liveSources.length > 1;

    // 首次加载时隐藏分组筛选
    final showGroupFilter = !_isInitialLoad && _channelGroups.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? const Color(0xFF1e1e1e).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.8),
      ),
      child: Row(
        children: [
          // 直播源筛选（只有多个源时显示）
          if (showSourceFilter) ...[
            _buildFilterPill('直播源', sourceOptions, _currentSource?.key ?? '', (
              value,
            ) {
              final source = _liveSources.firstWhere((s) => s.key == value);
              _loadChannels(source: source);
              _scrollToTop();
            }, themeService),
            const SizedBox(width: 8),
          ],
          // 分组筛选（首次加载完成后才显示）
          if (showGroupFilter)
            _buildFilterPill('分组', groupOptions, _selectedGroup, (value) {
              widget.viewModel.selectGroup(value);
              _scrollToTop();
            }, themeService),
          const Spacer(),
          // 刷新按钮
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: MouseRegion(
              cursor: DeviceUtils.isPC() && !_isRefreshing
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onEnter: DeviceUtils.isPC() && !_isRefreshing
                  ? (_) {
                      setState(() {
                        _isRefreshButtonHovered = true;
                      });
                    }
                  : null,
              onExit: DeviceUtils.isPC() && !_isRefreshing
                  ? (_) {
                      setState(() {
                        _isRefreshButtonHovered = false;
                      });
                    }
                  : null,
              child: GestureDetector(
                onTap: _isRefreshing ? null : refreshChannels,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: RotationTransition(
                      turns: _refreshIconController,
                      child: Icon(
                        Icons.refresh,
                        size: 20,
                        color: _isRefreshing
                            ? const Color(0xFF27ae60)
                            : (DeviceUtils.isPC() && _isRefreshButtonHovered
                                  ? const Color(0xFF27ae60)
                                  : (themeService.isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[500])),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    String title,
    List<SelectorOption> options,
    String selectedValue,
    ValueChanged<String> onSelected,
    ThemeViewModel themeService,
  ) {
    final selectedOption = options.firstWhere(
      (e) => e.value == selectedValue,
      orElse: () => options.first,
    );
    final isDefault = selectedValue == '全部' || selectedValue.isEmpty;

    return FilterPillHover(
      isPC: DeviceUtils.isPC(),
      isDefault: isDefault,
      title: title,
      selectedOption: selectedOption,
      onTap: () {
        _showFilterOptions(context, title, options, selectedValue, onSelected);
      },
    );
  }

  void _showFilterOptions(
    BuildContext context,
    String title,
    List<SelectorOption> options,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    if (DeviceUtils.isPC()) {
      // PC端使用 filter_options_selector.dart 中的 PC 组件
      showFilterOptionsSelector(
        context: context,
        title: title,
        options: options,
        selectedValue: selectedValue,
        onSelected: onSelected,
        useCompactLayout: title == '分组', // 只有标题筛选使用紧凑布局
      );
    } else {
      // 移动端显示底部弹出
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final modalWidth = DeviceUtils.isTablet(context)
              ? screenWidth * 0.5
              : screenWidth;
          const horizontalPadding = 16.0;
          const spacing = 10.0;
          final itemWidth =
              (modalWidth - horizontalPadding * 2 - spacing * 2) / 3;

          return Container(
            width: DeviceUtils.isTablet(context)
                ? modalWidth
                : double.infinity, // 设置宽度为100%
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                    minHeight: 200.0,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.start, // 左对齐
                        spacing: spacing,
                        runSpacing: spacing,
                        children: options.map((option) {
                          final isSelected = option.value == selectedValue;
                          return SizedBox(
                            width: itemWidth,
                            child: InkWell(
                              onTap: () {
                                onSelected(option.value);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                alignment: Alignment.centerLeft, // 内容左对齐
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF27AE60)
                                      : Theme.of(
                                          context,
                                        ).chipTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  option.label,
                                  textAlign: TextAlign.left, // 文字左对齐
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildLoadingView(ThemeViewModel themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: FontUtils.poppins(
              color: themeService.isDarkMode
                  ? const Color(0xFFb0b0b0)
                  : const Color(0xFF7f8c8d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshingView(ThemeViewModel themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
          ),
          const SizedBox(height: 16),
          Text(
            '刷新中...',
            style: FontUtils.poppins(
              color: themeService.isDarkMode
                  ? const Color(0xFFb0b0b0)
                  : const Color(0xFF7f8c8d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeViewModel themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: themeService.isDarkMode
                ? const Color(0xFF666666)
                : const Color(0xFF95a5a6),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '加载失败',
            style: FontUtils.poppins(
              color: themeService.isDarkMode
                  ? const Color(0xFFb0b0b0)
                  : const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: refreshChannels,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27ae60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('刷新', style: FontUtils.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(ThemeViewModel themeService) {
    final channels = _getFilteredChannels();

    if (channels.isEmpty) {
      return Center(
        child: Text(
          '暂无频道',
          style: FontUtils.poppins(
            color: themeService.isDarkMode
                ? const Color(0xFFb0b0b0)
                : const Color(0xFF7f8c8d),
          ),
        ),
      );
    }

    // 非 PC 平台直接使用 2 列，PC 平台根据宽度计算列数
    final int crossAxisCount = DeviceUtils.getLiveChannelColumnCount(context);
    const double childAspectRatio = 1.5;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return _buildChannelCard(channels[index], themeService);
      },
    );
  }

  Widget _buildChannelCard(LiveChannel channel, ThemeViewModel themeService) {
    return _LiveChannelCard(
      channel: channel,
      themeService: themeService,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LivePlayerScreen(
              viewModelFactory: () =>
                  widget.playerViewModelFactory(channel, _currentSource!),
              dlnaCastViewModelFactory: widget.dlnaCastViewModelFactory,
            ),
          ),
        ).then((_) {
          if (mounted) {
            _loadChannels();
          }
        });
      },
      buildChannelLogo: _buildChannelLogo,
    );
  }

  Widget _buildChannelLogo(LiveChannel channel, ThemeViewModel themeService) {
    // 如果有台标，显示台标
    if (channel.logo.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeService.isDarkMode
              ? const Color(0xFF2a2a2a)
              : const Color(0xFFc0c0c0),
        ),
        child: Image.network(
          channel.logo,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultPreview(themeService);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDefaultPreview(themeService);
          },
        ),
      );
    }
    // 没有台标，显示默认图标
    return _buildDefaultPreview(themeService);
  }

  Widget _buildDefaultPreview(ThemeViewModel themeService) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? const Color(0xFF2a2a2a)
            : const Color(0xFFc0c0c0),
      ),
      child: Center(
        child: Icon(
          Icons.tv,
          size: 48,
          color: themeService.isDarkMode
              ? const Color(0xFF666666)
              : const Color(0xFF95a5b0),
        ),
      ),
    );
  }
}

class _LiveChannelCard extends StatefulWidget {
  final LiveChannel channel;
  final ThemeViewModel themeService;
  final VoidCallback onTap;
  final Widget Function(LiveChannel, ThemeViewModel) buildChannelLogo;

  const _LiveChannelCard({
    required this.channel,
    required this.themeService,
    required this.onTap,
    required this.buildChannelLogo,
  });

  @override
  State<_LiveChannelCard> createState() => _LiveChannelCardState();
}

class _LiveChannelCardState extends State<_LiveChannelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPC = DeviceUtils.isPC();

    return MouseRegion(
      cursor: isPC ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: isPC ? (_) => setState(() => _isHovered = true) : null,
      onExit: isPC ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: isPC && _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 卡片主体 - 2:1 长宽比
              Expanded(
                child: AspectRatio(
                  aspectRatio: 2.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.themeService.isDarkMode
                          ? const Color(0xFF1e1e1e)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.buildChannelLogo(
                            widget.channel,
                            widget.themeService,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 标题 - 放在卡片下方居中
              const SizedBox(height: 8),
              Text(
                widget.channel.name,
                style: FontUtils.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPC && _isHovered
                      ? const Color(0xFF27ae60)
                      : (widget.themeService.isDarkMode
                            ? Colors.white
                            : const Color(0xFF2c3e50)),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
