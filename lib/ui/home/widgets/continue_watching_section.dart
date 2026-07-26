import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/domain/models/video_info.dart';
import 'package:selene/ui/core/view_models/theme_view_model.dart';
import 'package:selene/ui/core/widgets/shimmer_effect.dart';
import 'package:selene/ui/core/widgets/video_card.dart';
import 'package:selene/ui/core/widgets/video_menu_bottom_sheet.dart';
import 'package:selene/ui/home/view_models/home_view_model.dart';
import 'package:selene/utils/device_utils.dart';
import 'package:selene/utils/font_utils.dart';
import 'package:selene/utils/image_url.dart';

/// 继续观看组件
class ContinueWatchingSection extends StatefulWidget {
  final HomeViewModel viewModel;
  final Function(PlayRecord)? onVideoTap;
  final Function(PlayRecord, VideoMenuAction)? onGlobalMenuAction;
  final VoidCallback? onViewAll;

  const ContinueWatchingSection({
    super.key,
    required this.viewModel,
    this.onVideoTap,
    this.onGlobalMenuAction,
    this.onViewAll,
  });

  @override
  State<ContinueWatchingSection> createState() =>
      _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection>
    with TickerProviderStateMixin {
  List<PlayRecord> _playRecords = [];
  bool _isLoading = true;
  bool _hasError = false;

  // 滚动控制相关
  final ScrollController _scrollController = ScrollController();
  bool _showLeftScroll = false;
  bool _showRightScroll = false;
  bool _isHovered = false;

  // hover 状态
  bool _isClearButtonHovered = false;
  bool _isMoreButtonHovered = false;

  @override
  void initState() {
    super.initState();

    widget.viewModel.addListener(_syncViewModel);

    // 添加滚动监听
    _scrollController.addListener(_checkScroll);

    // 首帧后同步可能已在父组件初始化期间完成的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncViewModel();
        _checkScroll();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScroll);
    _scrollController.dispose();
    widget.viewModel.removeListener(_syncViewModel);
    super.dispose();
  }

  void _syncViewModel() {
    if (!mounted) return;
    final state = widget.viewModel.state;
    setState(() {
      _playRecords = state.playRecords;
      _isLoading = state.playRecordsLoading;
      _hasError = state.playRecordsError != null;
    });
  }

  void _checkScroll() {
    if (!mounted) return;

    if (!_scrollController.hasClients) {
      // 如果还没有客户端，但有播放记录数据，显示右侧按钮
      if (_playRecords.isNotEmpty && _playRecords.length > 3) {
        setState(() {
          _showLeftScroll = false;
          _showRightScroll = true;
        });
      }
      return;
    }

    final position = _scrollController.position;
    const threshold = 1.0; // 容差值，避免浮点误差

    setState(() {
      _showLeftScroll = position.pixels > threshold;
      _showRightScroll = position.pixels < position.maxScrollExtent - threshold;
    });
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;

    // 根据可见卡片数动态计算滚动距离
    final double visibleCards = DeviceUtils.getHorizontalVisibleCards(
      context,
      2.75,
    );
    final double screenWidth = MediaQuery.of(context).size.width;
    const double padding = 32.0;
    const double spacing = 12.0;
    final double availableWidth = screenWidth - padding;
    final double cardWidth =
        (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
    // 每次滚动约 5 个卡片的距离
    final double scrollDistance = (cardWidth + spacing) * 5;

    _scrollController.animateTo(
      math.max(0, _scrollController.offset - scrollDistance),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;

    // 根据可见卡片数动态计算滚动距离
    final double visibleCards = DeviceUtils.getHorizontalVisibleCards(
      context,
      2.75,
    );
    final double screenWidth = MediaQuery.of(context).size.width;
    const double padding = 32.0;
    const double spacing = 12.0;
    final double availableWidth = screenWidth - padding;
    final double cardWidth =
        (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
    // 每次滚动约 5 个卡片的距离
    final double scrollDistance = (cardWidth + spacing) * 5;

    _scrollController.animateTo(
      math.min(
        _scrollController.position.maxScrollExtent,
        _scrollController.offset + scrollDistance,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 加载播放记录
  Future<void> _loadPlayRecords() async {
    await widget.viewModel.refreshPlayRecords.execute();
    if (mounted) {
      _preloadImages(widget.viewModel.state.playRecords);
    }
  }

  /// 预加载图片
  Future<void> _preloadImages(List<PlayRecord> records) async {
    if (!mounted) return;

    // 只预加载前几个图片，避免过度预加载
    final int preloadCount = math.min(records.length, 5);
    for (int i = 0; i < preloadCount; i++) {
      if (!mounted) break;

      final record = records[i];
      final imageUrl = await getImageUrl(record.cover, record.source);
      if (!mounted) break;
      if (imageUrl.isNotEmpty) {
        final headers = getImageRequestHeaders(imageUrl, record.source);
        final provider = NetworkImage(imageUrl, headers: headers);
        precacheImage(provider, context);
      }
    }
  }

  /// 显示清空确认弹窗
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeViewModel>(
          builder: (context, themeService, child) {
            return AlertDialog(
              backgroundColor: themeService.isDarkMode
                  ? const Color(0xFF1e1e1e)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFe74c3c).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFe74c3c),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 标题
                  Text(
                    '清空播放记录',
                    style: FontUtils.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: themeService.isDarkMode
                          ? const Color(0xFFffffff)
                          : const Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 描述
                  Text(
                    '确定要清空所有播放记录吗？此操作无法撤销。',
                    style: FontUtils.poppins(
                      fontSize: 14,
                      color: themeService.isDarkMode
                          ? const Color(0xFFb0b0b0)
                          : const Color(0xFF7f8c8d),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // 按钮
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '取消',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: themeService.isDarkMode
                                  ? const Color(0xFFb0b0b0)
                                  : const Color(0xFF7f8c8d),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _clearPlayRecords();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFe74c3c),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            '清空',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 清空播放记录
  Future<void> _clearPlayRecords() async {
    final response = await widget.viewModel.clearRecords.execute();
    if (!mounted) return;
    if (response == null) return;
    final success = response.isSuccess;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '播放记录已清空' : response.failureOrNull!.message,
          style: FontUtils.poppins(color: Colors.white),
        ),
        backgroundColor: success
            ? const Color(0xFF27ae60)
            : const Color(0xFFe74c3c),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有数据且不在加载中，隐藏组件
    if (!_isLoading && _playRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final isPC = DeviceUtils.isPC();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题、清空按钮和查看更多按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧：标题和清空按钮
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Consumer<ThemeViewModel>(
                      builder: (context, themeService, child) {
                        return Text(
                          '继续观看',
                          style: FontUtils.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: themeService.isDarkMode
                                ? const Color(0xFFffffff)
                                : const Color(0xFF2c3e50),
                          ),
                        );
                      },
                    ),
                    if (_playRecords.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: DeviceUtils.isPC()
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        onEnter: DeviceUtils.isPC()
                            ? (_) {
                                setState(() {
                                  _isClearButtonHovered = true;
                                });
                              }
                            : null,
                        onExit: DeviceUtils.isPC()
                            ? (_) {
                                setState(() {
                                  _isClearButtonHovered = false;
                                });
                              }
                            : null,
                        child: TextButton(
                          onPressed: _showClearConfirmation,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            overlayColor: Colors.transparent,
                          ),
                          child: Text(
                            '清空',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: DeviceUtils.isPC() && _isClearButtonHovered
                                  ? const Color(0xFFe74c3c) // hover 时红色
                                  : const Color(0xFF7f8c8d),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // 右侧：查看更多按钮
                if (_playRecords.isNotEmpty)
                  MouseRegion(
                    cursor: DeviceUtils.isPC()
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    onEnter: DeviceUtils.isPC()
                        ? (_) {
                            setState(() {
                              _isMoreButtonHovered = true;
                            });
                          }
                        : null,
                    onExit: DeviceUtils.isPC()
                        ? (_) {
                            setState(() {
                              _isMoreButtonHovered = false;
                            });
                          }
                        : null,
                    child: TextButton(
                      onPressed: widget.onViewAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: Colors.transparent,
                      ),
                      child: Text(
                        '查看全部 >',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: DeviceUtils.isPC() && _isMoreButtonHovered
                              ? const Color(0xFF27ae60) // hover 时绿色
                              : const Color(0xFF7f8c8d),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 内容区域
          if (_isLoading)
            _buildLoadingState()
          else if (_hasError)
            _buildErrorState()
          else
            isPC ? _buildContentWithScrollButtons() : _buildContent(),
        ],
      ),
    );
  }

  /// 构建带滚动按钮的内容区域（PC端）
  Widget _buildContentWithScrollButtons() {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        // 延迟检查以确保滚动控制器已初始化
        Future.delayed(const Duration(milliseconds: 50), _checkScroll);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          _buildContent(),
          // 左侧滚动按钮 - 定位在可视区域内
          if (_showLeftScroll)
            Positioned(
              left: 0,
              top: 0,
              bottom: 60,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 80,
                  color: Colors.transparent,
                  child: IgnorePointer(
                    ignoring: !_isHovered,
                    child: AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: _buildScrollButton(
                          icon: Icons.chevron_left,
                          onPressed: _scrollLeft,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 右侧滚动按钮 - 定位在可视区域内
          if (_showRightScroll)
            Positioned(
              right: 0,
              top: 0,
              bottom: 60,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 80,
                  color: Colors.transparent,
                  child: IgnorePointer(
                    ignoring: !_isHovered,
                    child: AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: _buildScrollButton(
                          icon: Icons.chevron_right,
                          onPressed: _scrollRight,
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

  /// 构建滚动按钮
  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeService, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? const Color(0xE61F2937)
                    : const Color(0xF2FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeService.isDarkMode
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: themeService.isDarkMode
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF4B5563),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据宽度动态展示卡片数：平板模式 5.75/6.75/7.75，手机模式 2.75
        final double visibleCards = DeviceUtils.getHorizontalVisibleCards(
          context,
          2.75,
        );

        // 计算卡片宽度
        final double screenWidth = constraints.maxWidth;
        const double padding = 32.0; // 左右padding (16 * 2)
        const double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        const double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        final double cardHeight = (cardWidth * 1.5) + 50; // 缓存高度计算

        return SizedBox(
          height: cardHeight, // 使用缓存的高度
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _playRecords.length,
            itemBuilder: (context, index) {
              final playRecord = _playRecords[index];
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < _playRecords.length - 1 ? spacing : 0,
                ),
                child: VideoCard(
                  videoInfo: VideoInfo.fromPlayRecord(playRecord),
                  onTap: () => widget.onVideoTap?.call(playRecord),
                  from: 'playrecord',
                  cardWidth: cardWidth, // 使用动态计算的宽度
                  onGlobalMenuAction: (action) =>
                      widget.onGlobalMenuAction?.call(playRecord, action),
                  isFavorited: widget.viewModel.isFavorited(
                    playRecord.source,
                    playRecord.id,
                  ), // 同步检测收藏状态
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据宽度动态展示卡片数：平板模式 5.75/6.75/7.75，手机模式 2.75
        final double visibleCards = DeviceUtils.getHorizontalVisibleCards(
          context,
          2.75,
        );
        final isTablet = DeviceUtils.isTablet(context);
        final int skeletonCount = isTablet ? visibleCards.ceil() : 3; // 骨架卡片数量

        // 计算卡片宽度
        final double screenWidth = constraints.maxWidth;
        const double padding = 32.0; // 左右padding (16 * 2)
        const double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        const double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        final double cardHeight = (cardWidth * 1.5) + 50; // 缓存高度计算

        return Container(
          height: cardHeight, // 使用缓存的高度
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: skeletonCount,
            itemBuilder: (context, index) {
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < skeletonCount - 1 ? spacing : 0,
                ),
                child: _buildSkeletonCard(cardWidth),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.4; // 保持与VideoCard相同的比例

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 封面骨架
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 6),
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        // 源名称骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.6,
            height: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              '加载播放记录失败',
              style: FontUtils.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPlayRecords,
              child: Text(
                '重试',
                style: FontUtils.poppins(
                  fontSize: 12,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
