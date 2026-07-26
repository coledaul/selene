import 'package:flutter/material.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : null,
          gradient: isDark
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
                  stops: [0, 0.18, 0.38, 0.60, 0.80, 1],
                ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? Colors.white : const Color(0xFF2c3e50),
              ),
              const SizedBox(height: 24),
              Text(
                '正在检查登录状态...',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF2c3e50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
