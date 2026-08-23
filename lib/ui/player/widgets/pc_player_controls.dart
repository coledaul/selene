import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../video_playback_session.dart';
import 'buffered_video_progress_bar.dart';
import 'player_overlay_title.dart';

// 桌面端带 hover 效果的按钮组件
class HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const HoverButton({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: widget.padding,
          decoration: _isHovering
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withValues(alpha: 0.5),
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}

class PCPlayerControls extends StatefulWidget {
  final VideoState state;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPause;
  final bool canCast;
  final Future<void> Function() onCastRequested;
  final bool isLastEpisode;
  final bool isLoadingVideo;
  final String? overlayTitle;
  final Function(bool isWebFullscreen)? onWebFullscreenChanged;
  final Function(VoidCallback)? onExitWebFullscreenCallbackReady;
  final VoidCallback? onExitFullScreen;
  final bool live;
  final Future<void> Function() onPlayRequested;
  final Future<void> Function() onPauseRequested;
  final Future<void> Function(double speed) onSetSpeed;
  final Future<void> Function(double volume) onSetVolume;
  final VideoPlaybackState playbackState;
  final Future<void> Function(Duration position) onSeekRequested;

  const PCPlayerControls({
    super.key,
    required this.state,
    this.onBackPressed,
    this.onNextEpisode,
    this.onPause,
    required this.canCast,
    required this.onCastRequested,
    this.isLastEpisode = false,
    this.isLoadingVideo = false,
    this.overlayTitle,
    this.onWebFullscreenChanged,
    this.onExitWebFullscreenCallbackReady,
    this.onExitFullScreen,
    this.live = false,
    required this.onPlayRequested,
    required this.onPauseRequested,
    required this.onSetSpeed,
    required this.onSetVolume,
    required this.playbackState,
    required this.onSeekRequested,
  });

  @override
  State<PCPlayerControls> createState() => _PCPlayerControlsState();
}

class _PCPlayerControlsState extends State<PCPlayerControls> {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  Size? _screenSize;
  Duration? _dragPosition;
  bool _isSeekingViaSwipe = false;
  double _swipeStartX = 0;
  Duration _swipeStartPosition = Duration.zero;
  bool _isFullscreen = false;
  bool _isWebFullscreen = false;
  bool _showSpeedMenu = false;
  final GlobalKey _speedButtonKey = GlobalKey();
  bool _isHoveringSpeedButton = false;
  bool _isHoveringSpeedMenu = false;
  bool _showVolumeMenu = false;
  final GlobalKey _volumeButtonKey = GlobalKey();
  bool _isHoveringVolumeButton = false;
  bool _isHoveringVolumeMenu = false;
  double _volumeBeforeMute = 1.0;
  Timer? _volumeMenuHideTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 注册退出网页全屏的回调
    widget.onExitWebFullscreenCallbackReady?.call(exitWebFullscreen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _forceStartHideTimer();
        // 请求焦点以接收键盘事件
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  void didUpdateWidget(PCPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackState.playing != widget.playbackState.playing) {
      if (widget.playbackState.playing) {
        if (_controlsVisible) _startHideTimer();
      } else {
        _hideTimer?.cancel();
        if (!_controlsVisible) setState(() => _controlsVisible = true);
      }
    }
    // 当 widget 更新时，尝试同步全屏状态
    // 使用 try-catch 避免在不安全的时机访问 InheritedWidget
    try {
      final actualFullscreen = widget.state.isFullscreen();
      if (_isFullscreen != actualFullscreen) {
        // 检测到从全屏退出
        if (_isFullscreen && !actualFullscreen) {
          widget.onExitFullScreen?.call();
        }
        setState(() {
          _isFullscreen = actualFullscreen;
        });
      }
    } catch (e) {
      // 如果无法安全获取状态，保持当前状态不变
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _volumeMenuHideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    // 如果倍速菜单或音量菜单正在显示或鼠标悬停在按钮/菜单上，不启动隐藏定时器
    if (_showSpeedMenu ||
        _isHoveringSpeedButton ||
        _isHoveringSpeedMenu ||
        _showVolumeMenu ||
        _isHoveringVolumeButton ||
        _isHoveringVolumeMenu) {
      return;
    }
    if (widget.playbackState.playing) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _controlsVisible = false;
          });
        }
      });
    }
  }

  void _forceStartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _onUserInteraction() {
    setState(() {
      _controlsVisible = true;
    });
    _startHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showVolumeMenuTemporarily() {
    // 取消之前的定时器
    _volumeMenuHideTimer?.cancel();

    // 显示音量条
    setState(() {
      _showVolumeMenu = true;
    });

    // 1秒后自动隐藏
    _volumeMenuHideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && !_isHoveringVolumeButton && !_isHoveringVolumeMenu) {
        setState(() {
          _showVolumeMenu = false;
        });
      }
    });
  }

  void _onBlankAreaTap() {
    // live 模式下不响应空白区域点击
    if (widget.live) {
      return;
    }
    // 单击空白区域切换播放/暂停
    if (widget.playbackState.playing) {
      unawaited(widget.onPauseRequested());
      widget.onPause?.call();
    } else {
      unawaited(widget.onPlayRequested());
    }
    setState(() {});
  }

  void _onBlankAreaDoubleTap() {
    // 双击空白区域切换全屏
    // 如果在网页全屏模式，先切换到真全屏
    if (_isWebFullscreen && !_isFullscreen) {
      _toggleWebFullscreen();
    }
    _toggleFullscreen();
  }

  void _onSeekStart() {
    if (!mounted) return;
    setState(() {
      _controlsVisible = true;
      _dragPosition = null;
    });
    _hideTimer?.cancel();
    _startHideTimer();
  }

  void _onSeekEnd() {
    setState(() {
      _dragPosition = null;
    });
    _startHideTimer();
  }

  void _onSwipeStart(DragStartDetails details) {
    if (!mounted || widget.live) return;

    setState(() {
      _isSeekingViaSwipe = true;
      _swipeStartX = details.globalPosition.dx;
      _swipeStartPosition = widget.playbackState.position;
      _controlsVisible = true;
    });

    _hideTimer?.cancel();
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    if (!mounted || !_isSeekingViaSwipe || _screenSize == null || widget.live) {
      return;
    }

    final screenWidth = _screenSize!.width;
    final swipeDistance = details.globalPosition.dx - _swipeStartX;
    final swipeRatio = swipeDistance / (screenWidth * 0.5);
    final duration = widget.playbackState.duration;

    final targetPosition =
        _swipeStartPosition +
        Duration(
          milliseconds: (duration.inMilliseconds * swipeRatio * 0.1).round(),
        );
    final clampedPosition = Duration(
      milliseconds: targetPosition.inMilliseconds.clamp(
        0,
        duration.inMilliseconds,
      ),
    );

    setState(() {
      _dragPosition = clampedPosition;
    });
  }

  void _onSwipeEnd(DragEndDetails details) {
    if (!mounted || !_isSeekingViaSwipe || widget.live) return;

    if (_dragPosition != null) {
      unawaited(widget.onSeekRequested(_dragPosition!));
    }

    setState(() {
      _isSeekingViaSwipe = false;
      _dragPosition = null;
    });

    _startHideTimer();
  }

  void _toggleFullscreen() {
    // 直接触发全屏切换，不要提前更新本地状态
    // 状态会在 didUpdateWidget 中同步
    if (_isFullscreen) {
      widget.state.exitFullscreen();
    } else {
      widget.state.enterFullscreen();
    }
  }

  void _toggleWebFullscreen() {
    final wasWebFullscreen = _isWebFullscreen;
    setState(() {
      _isWebFullscreen = !_isWebFullscreen;
    });
    // 通知父组件网页全屏状态变化
    widget.onWebFullscreenChanged?.call(_isWebFullscreen);
    // 如果从网页全屏退出，触发回调
    if (wasWebFullscreen && !_isWebFullscreen) {
      widget.onExitFullScreen?.call();
    }
    _onUserInteraction();
  }

  /// 退出网页全屏（公开方法，供外部调用）
  void exitWebFullscreen() {
    if (_isWebFullscreen) {
      setState(() {
        _isWebFullscreen = false;
      });
      // 通知父组件网页全屏状态变化
      widget.onWebFullscreenChanged?.call(false);
      // 触发退出全屏回调
      widget.onExitFullScreen?.call();
      _onUserInteraction();
    }
  }

  Future<void> _requestCast() async {
    // 如果在全屏状态，通知父组件并退出全屏
    if (_isFullscreen) {
      _toggleFullscreen();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
    }
    await widget.onCastRequested();
  }

  // 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // 只处理按键按下事件
    if (event is KeyDownEvent) {
      // ESC 键退出全屏
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isFullscreen) {
          _toggleFullscreen();
          return KeyEventResult.handled;
        }
      }
      // 空格键播放/暂停
      else if (event.logicalKey == LogicalKeyboardKey.space) {
        _onUserInteraction();
        if (widget.playbackState.playing) {
          unawaited(widget.onPauseRequested());
          widget.onPause?.call();
        } else {
          unawaited(widget.onPlayRequested());
        }
        setState(() {});
        return KeyEventResult.handled;
      }
      // F 键切换全屏
      else if (event.logicalKey == LogicalKeyboardKey.keyF) {
        if (_isWebFullscreen) {
          _toggleWebFullscreen();
          return KeyEventResult.handled;
        }
        _toggleFullscreen();
        return KeyEventResult.handled;
      }
      // 左方向键快退 10 秒
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        final currentPosition = widget.playbackState.position;
        final newPosition = currentPosition - const Duration(seconds: 10);
        final clampedPosition = Duration(
          milliseconds: newPosition.inMilliseconds.clamp(
            0,
            widget.playbackState.duration.inMilliseconds,
          ),
        );
        unawaited(widget.onSeekRequested(clampedPosition));
        // 显示控制栏
        _onUserInteraction();
        return KeyEventResult.handled;
      }
      // 右方向键快进 10 秒
      else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final currentPosition = widget.playbackState.position;
        final duration = widget.playbackState.duration;
        final newPosition = currentPosition + const Duration(seconds: 10);
        final clampedPosition = Duration(
          milliseconds: newPosition.inMilliseconds.clamp(
            0,
            duration.inMilliseconds,
          ),
        );
        unawaited(widget.onSeekRequested(clampedPosition));
        // 显示控制栏
        _onUserInteraction();
        return KeyEventResult.handled;
      }
      // 上方向键增加音量 10%
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        final currentVolume = widget.playbackState.volume;
        final newVolume = (currentVolume + 10).clamp(0.0, 100.0);
        unawaited(widget.onSetVolume(newVolume));
        // 显示控制栏和音量条
        _onUserInteraction();
        _showVolumeMenuTemporarily();
        return KeyEventResult.handled;
      }
      // 下方向键减少音量 10%
      else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final currentVolume = widget.playbackState.volume;
        final newVolume = (currentVolume - 10).clamp(0.0, 100.0);
        unawaited(widget.onSetVolume(newVolume));
        // 显示控制栏和音量条
        _onUserInteraction();
        _showVolumeMenuTemporarily();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在加载视频，只显示加载界面
    if (widget.isLoadingVideo) {
      return Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                '加载中...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // 使用网页全屏或真全屏的样式
    final effectiveFullscreen = _isWebFullscreen || _isFullscreen;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: (effectiveFullscreen && !_controlsVisible)
            ? SystemMouseCursors.none
            : SystemMouseCursors.basic,
        onEnter: (_) {
          // 鼠标进入时显示控制栏并启动隐藏定时器
          if (!_controlsVisible) {
            setState(() {
              _controlsVisible = true;
            });
          }
          _startHideTimer();
        },
        onHover: (_) {
          // 鼠标移动时重置隐藏定时器
          if (!_controlsVisible) {
            setState(() {
              _controlsVisible = true;
            });
          }
          _startHideTimer();
        },
        onExit: (_) {
          // 鼠标移出时立即隐藏控制栏，但如果菜单正在显示或鼠标在按钮/菜单上则不隐藏
          _hideTimer?.cancel();
          if (_controlsVisible &&
              !_showSpeedMenu &&
              !_isHoveringSpeedButton &&
              !_isHoveringSpeedMenu &&
              !_showVolumeMenu &&
              !_isHoveringVolumeButton &&
              !_isHoveringVolumeMenu) {
            setState(() {
              _controlsVisible = false;
            });
          }
        },
        child: Stack(
          children: [
            // 背景层 - 处理滑动手势
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragStart: _onSwipeStart,
                onHorizontalDragUpdate: _onSwipeUpdate,
                onHorizontalDragEnd: _onSwipeEnd,
                onTap: _onBlankAreaTap,
                onDoubleTap: _onBlankAreaDoubleTap,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 顶部渐变背景 - 从上往下（半透明黑色到完全透明）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  child: Container(
                    height: effectiveFullscreen ? 120 : 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 底部渐变背景 - 从下往上（半透明黑色到完全透明）
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  child: Container(
                    height: effectiveFullscreen ? 140 : 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 顶部返回按钮
            Positioned(
              top: effectiveFullscreen ? 8 : 4,
              left: effectiveFullscreen ? 16.0 : 8.0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: HoverButton(
                    onTap: () async {
                      _onUserInteraction();
                      if (_isFullscreen) {
                        _toggleFullscreen();
                      } else if (_isWebFullscreen) {
                        _toggleWebFullscreen();
                      } else {
                        widget.onBackPressed?.call();
                      }
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: effectiveFullscreen ? 24 : 20,
                    ),
                  ),
                ),
              ),
            ),
            PlayerOverlayTitle(
              title: widget.overlayTitle,
              visible: _controlsVisible,
              top: effectiveFullscreen ? 16 : 12,
              left: effectiveFullscreen ? 72 : 64,
              right: effectiveFullscreen ? 72 : 64,
            ),
            // 顶部投屏按钮
            if (widget.canCast)
              Positioned(
                top: effectiveFullscreen ? 8 : 4,
                right: effectiveFullscreen ? 16.0 : 8.0,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: HoverButton(
                      onTap: () async {
                        _onUserInteraction();
                        await _requestCast();
                      },
                      child: Icon(
                        Icons.cast,
                        color: Colors.white,
                        size: effectiveFullscreen ? 24 : 20,
                      ),
                    ),
                  ),
                ),
              ),
            // 中央播放/暂停按钮 - 暂停时始终显示
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: (!widget.playbackState.playing || _controlsVisible)
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: widget.playbackState.playing && !_controlsVisible,
                    child: _CenterPlayButton(
                      isPlaying: widget.playbackState.playing,
                      isFullscreen: effectiveFullscreen,
                      onTap: () {
                        _onUserInteraction();
                        if (widget.playbackState.playing) {
                          unawaited(widget.onPauseRequested());
                          widget.onPause?.call();
                        } else {
                          unawaited(widget.onPlayRequested());
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            // 进度条
            Positioned(
              bottom: effectiveFullscreen ? 58.0 : 42.0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: Container(
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: BufferedVideoProgressBar(
                      position: _dragPosition ?? widget.playbackState.position,
                      duration: widget.playbackState.duration,
                      cachedRanges: widget.playbackState.cachedRanges,
                      onSeekRequested: widget.onSeekRequested,
                      onInteractionStart: _onSeekStart,
                      onInteractionEnd: _onSeekEnd,
                      onInteractionUpdate: () {
                        if (!_controlsVisible) {
                          setState(() {
                            _controlsVisible = true;
                          });
                        }
                        _hideTimer?.cancel();
                      },
                      onPreviewChanged: (duration) {
                        setState(() {
                          _dragPosition = duration;
                        });
                      },
                      isSeekingViaSwipe: _isSeekingViaSwipe,
                      live: widget.live,
                      style: BufferedVideoProgressStyle.desktop,
                    ),
                  ),
                ),
              ),
            ),
            // 底部控制栏
            Positioned(
              bottom: effectiveFullscreen ? 4.0 : -6.0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: effectiveFullscreen ? 16.0 : 8.0,
                        right: effectiveFullscreen ? 16.0 : 8.0,
                        top: effectiveFullscreen ? 0.0 : 0.0,
                        bottom: effectiveFullscreen ? 8.0 : 8.0,
                      ),
                      child: Row(
                        children: [
                          HoverButton(
                            onTap: () {
                              _onUserInteraction();
                              if (widget.playbackState.playing) {
                                unawaited(widget.onPauseRequested());
                                widget.onPause?.call();
                              } else {
                                unawaited(widget.onPlayRequested());
                              }
                            },
                            child: Icon(
                              widget.playbackState.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: effectiveFullscreen ? 28 : 24,
                            ),
                          ),
                          if (!widget.isLastEpisode && !widget.live)
                            Transform.translate(
                              offset: const Offset(-8, 0),
                              child: HoverButton(
                                onTap: () {
                                  _onUserInteraction();
                                  widget.onNextEpisode?.call();
                                },
                                child: Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                  size: effectiveFullscreen ? 28 : 24,
                                ),
                              ),
                            ),
                          Transform.translate(
                            offset: const Offset(-8, 0),
                            child: MouseRegion(
                              key: _volumeButtonKey,
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) {
                                setState(() {
                                  _isHoveringVolumeButton = true;
                                  _showVolumeMenu = true;
                                  _controlsVisible = true;
                                });
                                _hideTimer?.cancel();
                              },
                              onExit: (_) {
                                setState(() {
                                  _isHoveringVolumeButton = false;
                                });
                                // 延迟检查是否需要隐藏菜单
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    if (mounted &&
                                        !_isHoveringVolumeButton &&
                                        !_isHoveringVolumeMenu) {
                                      setState(() {
                                        _showVolumeMenu = false;
                                      });
                                      _startHideTimer();
                                    }
                                  },
                                );
                              },
                              child: GestureDetector(
                                onTap: () {
                                  _onUserInteraction();
                                  final currentVolume =
                                      widget.playbackState.volume;
                                  if (currentVolume > 0) {
                                    // 静音
                                    _volumeBeforeMute = currentVolume;
                                    unawaited(widget.onSetVolume(0));
                                  } else {
                                    // 恢复音量
                                    unawaited(
                                      widget.onSetVolume(_volumeBeforeMute),
                                    );
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: _isHoveringVolumeButton
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.withValues(
                                            alpha: 0.5,
                                          ),
                                        )
                                      : null,
                                  child: Icon(
                                    _getVolumeIcon(widget.playbackState.volume),
                                    color: Colors.white,
                                    size: effectiveFullscreen ? 22 : 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!widget.live)
                            Expanded(child: _buildPositionIndicator()),
                          if (!widget.live)
                            MouseRegion(
                              key: _speedButtonKey,
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) {
                                setState(() {
                                  _isHoveringSpeedButton = true;
                                  _showSpeedMenu = true;
                                  _controlsVisible = true;
                                });
                                _hideTimer?.cancel();
                              },
                              onExit: (_) {
                                setState(() {
                                  _isHoveringSpeedButton = false;
                                });
                                // 延迟检查是否需要隐藏菜单
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    if (mounted &&
                                        !_isHoveringSpeedButton &&
                                        !_isHoveringSpeedMenu) {
                                      setState(() {
                                        _showSpeedMenu = false;
                                      });
                                      _startHideTimer();
                                    }
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: _isHoveringSpeedButton
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
                                      )
                                    : null,
                                child: Icon(
                                  Icons.speed,
                                  color: Colors.white,
                                  size: effectiveFullscreen ? 22 : 20,
                                ),
                              ),
                            ),
                          if (widget.live) const Spacer(),
                          // 网页全屏按钮（仅在非真全屏时显示）
                          if (!_isFullscreen)
                            HoverButton(
                              onTap: () {
                                _onUserInteraction();
                                _toggleWebFullscreen();
                              },
                              child: Icon(
                                _isWebFullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fit_screen,
                                color: Colors.white,
                                size: effectiveFullscreen ? 28 : 24,
                              ),
                            ),
                          // 完全全屏按钮（仅在非网页全屏时显示）
                          if (!_isWebFullscreen)
                            HoverButton(
                              onTap: () {
                                _onUserInteraction();
                                _toggleFullscreen();
                              },
                              child: Icon(
                                _isFullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color: Colors.white,
                                size: effectiveFullscreen ? 28 : 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 倍速选择弹窗
            if (_showSpeedMenu) _buildSpeedMenu(),
            // 音量调节弹窗
            if (_showVolumeMenu) _buildVolumeMenu(),
          ],
        ),
      ),
    );
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) {
      return Icons.volume_off;
    } else if (volume < 50) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  Widget _buildSpeedMenu() {
    final speeds = [0.5, 0.75, 1.0, 1.5, 2.0];
    final currentSpeed = widget.playbackState.rate;

    // 获取速度按钮的位置
    final RenderBox? renderBox =
        _speedButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    // 根据全屏状态调整弹窗大小
    final effectiveFullscreen = _isWebFullscreen || _isFullscreen;
    final menuWidth = effectiveFullscreen ? 120.0 : 90.0;
    final itemHeight = effectiveFullscreen ? 48.0 : 36.0;
    final menuHeight = speeds.length * itemHeight;
    // 计算水平居中位置：按钮中心 - 弹框宽度的一半
    final menuLeft =
        buttonPosition.dx + (buttonSize.width / 2) - (menuWidth / 2);
    // 计算垂直位置：按钮顶部 - 弹框高度 - 间距
    final menuTop = buttonPosition.dy - menuHeight - (_isFullscreen ? 2 : 36);

    return Positioned(
      left: menuLeft,
      top: menuTop,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHoveringSpeedMenu = true;
          });
          _hideTimer?.cancel();
        },
        onExit: (_) {
          setState(() {
            _isHoveringSpeedMenu = false;
          });
          // 延迟检查是否需要隐藏菜单
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isHoveringSpeedButton && !_isHoveringSpeedMenu) {
              setState(() {
                _showSpeedMenu = false;
              });
              _startHideTimer();
            }
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: menuWidth,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(effectiveFullscreen ? 8 : 6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(effectiveFullscreen ? 8 : 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: speeds.map((speed) {
                  final isSelected = (speed - currentSpeed).abs() < 0.01;
                  return _SpeedMenuItem(
                    speed: speed,
                    isSelected: isSelected,
                    isFullscreen: effectiveFullscreen,
                    onTap: () {
                      widget.onSetSpeed(speed);
                      setState(() {
                        _showSpeedMenu = false;
                        _isHoveringSpeedMenu = false;
                      });
                      _startHideTimer();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeMenu() {
    final currentVolume = widget.playbackState.volume;

    // 获取音量按钮的位置
    final RenderBox? renderBox =
        _volumeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    // 根据全屏状态调整弹窗大小 - 更高更瘦
    final effectiveFullscreen = _isWebFullscreen || _isFullscreen;
    final menuWidth = effectiveFullscreen ? 42.0 : 36.0;
    final menuHeight = effectiveFullscreen ? 200.0 : 150.0;

    // 计算水平居中位置：按钮中心 - 弹框宽度的一半
    final menuLeft =
        buttonPosition.dx + (buttonSize.width / 2) - (menuWidth / 2);
    // 计算垂直位置：按钮顶部 - 弹框高度 - 间距
    final menuTop = buttonPosition.dy - menuHeight - (_isFullscreen ? 2 : 36);

    return Positioned(
      left: menuLeft,
      top: menuTop,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHoveringVolumeMenu = true;
          });
          _hideTimer?.cancel();
        },
        onExit: (_) {
          setState(() {
            _isHoveringVolumeMenu = false;
          });
          // 延迟检查是否需要隐藏菜单
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isHoveringVolumeButton && !_isHoveringVolumeMenu) {
              setState(() {
                _showVolumeMenu = false;
              });
              _startHideTimer();
            }
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: menuWidth,
            height: menuHeight,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(effectiveFullscreen ? 8 : 6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(effectiveFullscreen ? 8 : 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 音量百分比显示
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${currentVolume.round()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: effectiveFullscreen ? 14 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 垂直音量滑块
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12.0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragStart: (details) {
                              final localY = details.localPosition.dy;
                              final volume =
                                  ((1 - (localY / constraints.maxHeight)) * 100)
                                      .clamp(0.0, 100.0);
                              unawaited(widget.onSetVolume(volume));
                              setState(() {});
                            },
                            onVerticalDragUpdate: (details) {
                              final localY = details.localPosition.dy;
                              final volume =
                                  ((1 - (localY / constraints.maxHeight)) * 100)
                                      .clamp(0.0, 100.0);
                              unawaited(widget.onSetVolume(volume));
                              setState(() {});
                            },
                            onTapDown: (details) {
                              final localY = details.localPosition.dy;
                              final volume =
                                  ((1 - (localY / constraints.maxHeight)) * 100)
                                      .clamp(0.0, 100.0);
                              unawaited(widget.onSetVolume(volume));
                              setState(() {});
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 背景轨道
                                Container(
                                  width: effectiveFullscreen ? 5 : 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      effectiveFullscreen ? 2.5 : 2,
                                    ),
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                // 音量指示器
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: currentVolume / 100,
                                    child: Container(
                                      width: effectiveFullscreen ? 5 : 4,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          effectiveFullscreen ? 2.5 : 2,
                                        ),
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionIndicator() {
    final position = _dragPosition ?? widget.playbackState.position;
    final duration = widget.playbackState.duration;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        '${_formatDuration(position)} / ${_formatDuration(duration)}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

// 倍速菜单项组件
class _SpeedMenuItem extends StatefulWidget {
  final double speed;
  final bool isSelected;
  final bool isFullscreen;
  final VoidCallback onTap;

  const _SpeedMenuItem({
    required this.speed,
    required this.isSelected,
    required this.isFullscreen,
    required this.onTap,
  });

  @override
  State<_SpeedMenuItem> createState() => _SpeedMenuItemState();
}

class _SpeedMenuItemState extends State<_SpeedMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.isFullscreen ? 48.0 : 36.0,
          color: _isHovering
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            '${widget.speed}x',
            style: TextStyle(
              color: widget.isSelected ? Colors.red : Colors.white,
              fontSize: widget.isFullscreen ? 14 : 12,
              fontWeight: widget.isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// 中央播放/暂停按钮组件 - 支持 hover 效果
class _CenterPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool isFullscreen;
  final VoidCallback onTap;

  const _CenterPlayButton({
    required this.isPlaying,
    required this.isFullscreen,
    required this.onTap,
  });

  @override
  State<_CenterPlayButton> createState() => _CenterPlayButtonState();
}

class _CenterPlayButtonState extends State<_CenterPlayButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // 暂停时始终显示背景，播放时仅 hover 时显示背景
    final showBackground = !widget.isPlaying || _isHovering;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景圆形 - 使用 AnimatedOpacity 实现淡入淡出
            AnimatedOpacity(
              opacity: showBackground ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
                child: SizedBox(
                  width: widget.isFullscreen ? 64 : 48,
                  height: widget.isFullscreen ? 64 : 48,
                ),
              ),
            ),
            // 图标
            Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: widget.isFullscreen ? 64 : 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
