import 'dart:async';

import 'package:flutter/material.dart';

/// 标签点击在当前页与目标页之间淡入淡出，手势仍使用 PageView 的原生滑动。
///
/// 索引由外部持有；本组件仅拥有分页和动画资源，不复制页面或预加载中间页。
final class FadingTabView extends StatefulWidget {
  const FadingTabView({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.children,
  }) : assert(index >= 0 && index < children.length);

  final int index;
  final ValueChanged<int> onIndexChanged;
  final List<Widget> children;

  @override
  State<FadingTabView> createState() => _FadingTabViewState();
}

class _FadingTabViewState extends State<FadingTabView>
    with SingleTickerProviderStateMixin {
  static const _fadeOutDuration = Duration(milliseconds: 80);
  static const _fadeInDuration = Duration(milliseconds: 140);

  late final PageController _pages;
  late final AnimationController _opacity;
  ScrollHoldController? _scrollHold;
  late int _visibleIndex;
  int _generation = 0;
  bool _switching = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _visibleIndex = widget.index;
    // 选择状态由 index 恢复，避免 PageStorage 中的旧页码覆盖外部导航状态。
    _pages = PageController(initialPage: widget.index, keepPage: false);
    _opacity = AnimationController(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion && _switching) _selectPage();
  }

  @override
  void didUpdateWidget(FadingTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index &&
        (widget.index != _visibleIndex || _switching)) {
      _selectPage();
    }
  }

  void _selectPage() {
    final generation = ++_generation;
    _opacity.stop();
    _switching = true;
    if (!_pages.hasClients || !_pages.position.hasContentDimensions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation) return;
        _jumpToTarget();
        _switching = false;
        _opacity.value = 1;
      });
      return;
    }
    if (_reduceMotion) {
      _jumpToTarget();
      _switching = false;
      _opacity.value = 1;
      return;
    }
    // 点击可以打断尚未结束的手势惯性，淡出期间固定当前画面。
    _releaseScrollHold();
    _scrollHold = _pages.position.hold(() => _scrollHold = null);
    unawaited(_transition(generation));
  }

  Future<void> _transition(int generation) async {
    try {
      if ((_pages.page! - widget.index).abs() > 0.001) {
        await _opacity
            .animateTo(0, duration: _fadeOutDuration, curve: Curves.easeOut)
            .orCancel;
        if (!mounted || generation != _generation) return;
        _jumpToTarget();
      }
      _releaseScrollHold();
      await _opacity
          .animateTo(1, duration: _fadeInDuration, curve: Curves.easeOut)
          .orCancel;
      if (mounted && generation == _generation) _switching = false;
    } on TickerCanceled {
      // 快速改选、手势接管和销毁均会取消旧过渡，旧目标不能再次生效。
    }
  }

  void _jumpToTarget() {
    if (!_pages.hasClients) return;
    _releaseScrollHold();
    _visibleIndex = widget.index;
    _pages.jumpToPage(widget.index);
  }

  void _releaseScrollHold() {
    final hold = _scrollHold;
    _scrollHold = null;
    hold?.cancel();
  }

  bool _onScrollStart(ScrollStartNotification notification) {
    if (notification.depth == 0 &&
        notification.dragDetails != null &&
        _switching) {
      _generation++;
      _opacity.stop();
      _opacity.value = 1;
      _switching = false;
      if (_visibleIndex != widget.index) widget.onIndexChanged(_visibleIndex);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: _onScrollStart,
      child: FadeTransition(
        opacity: _opacity,
        child: PageView(
          controller: _pages,
          onPageChanged: (index) {
            _visibleIndex = index;
            if (!_switching && index != widget.index) {
              widget.onIndexChanged(index);
            }
          },
          children: widget.children,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    _releaseScrollHold();
    _opacity.dispose();
    _pages.dispose();
    super.dispose();
  }
}
