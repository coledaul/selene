import 'dart:async';

import 'package:flutter/material.dart';

typedef PlayerPageRetry = Future<void> Function();

/// 播放页面在播放器会话之外遇到的问题及其恢复动作。
final class PlayerPageProblem {
  const PlayerPageProblem({required this.message, this.retry});

  final String message;
  final PlayerPageRetry? retry;
}

/// 呈现播放页面级问题，不处理播放器会话内部的 open/play 错误。
final class PlayerPageProblemOverlay extends StatefulWidget {
  const PlayerPageProblemOverlay({
    super.key,
    required this.problem,
    required this.onBackPressed,
  });

  final PlayerPageProblem problem;
  final VoidCallback onBackPressed;

  @override
  State<PlayerPageProblemOverlay> createState() =>
      _PlayerPageProblemOverlayState();
}

final class _PlayerPageProblemOverlayState
    extends State<PlayerPageProblemOverlay> {
  bool _retrying = false;

  Future<void> _retry() async {
    final retry = widget.problem.retry;
    if (retry == null || _retrying) return;
    setState(() => _retrying = true);
    try {
      await retry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDarkMode ? Colors.black : Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? null
              : const LinearGradient(
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
                  stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
                ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 100,
              left: 40,
              child: _DecorationDot(size: 12, color: Colors.red),
            ),
            const Positioned(
              top: 140,
              left: 60,
              child: _DecorationDot(size: 8, color: Colors.orange),
            ),
            const Positioned(
              top: 120,
              right: 50,
              child: _DecorationDot(size: 10, color: Colors.amber),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFF8C42), Color(0xFFE74C3C)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('😵', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '哎呀, 出现了一些问题',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B4513).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.problem.message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFE74C3C),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '请检查网络连接或尝试刷新页面',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: widget.onBackPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                '返回上页',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (widget.problem.retry != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _retrying
                                    ? null
                                    : () => unawaited(_retry()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? const Color(0xFF2D3748)
                                      : const Color(0xFFE2E8F0),
                                  foregroundColor: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF3182CE),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _retrying ? '正在重试...' : '重新尝试',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF3182CE),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DecorationDot extends StatelessWidget {
  const _DecorationDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
