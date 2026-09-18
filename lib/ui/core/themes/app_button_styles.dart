import 'package:flutter/material.dart';

/// loading 仍通过 onPressed=null 禁止交互，但不应借用“不可用”的灰色配色。
/// 正常、按下、焦点与普通禁用状态继续交给原生按钮处理。
abstract final class AppButtonStyles {
  /// 视频遮罩始终是深色，不跟随页面明暗模式切换文字颜色。
  static final onMedia = ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.disabled) ? Colors.white38 : Colors.white,
    ),
  );

  static ButtonStyle? filled(
    BuildContext context, {
    required bool loading,
    ButtonStyle? style,
  }) => _resolve(loading, Theme.of(context).filledButtonTheme.style, style);

  static ButtonStyle? elevated(
    BuildContext context, {
    required bool loading,
    ButtonStyle? style,
  }) => _resolve(loading, Theme.of(context).elevatedButtonTheme.style, style);

  static ButtonStyle? _resolve(
    bool loading,
    ButtonStyle? themeStyle,
    ButtonStyle? style,
  ) {
    if (!loading) return style;
    final effective = (style ?? const ButtonStyle()).merge(themeStyle);
    const enabled = <WidgetState>{};
    final background =
        style?.backgroundColor?.resolve(enabled) ??
        themeStyle?.backgroundColor?.resolve(enabled);
    final foreground =
        style?.foregroundColor?.resolve(enabled) ??
        themeStyle?.foregroundColor?.resolve(enabled);
    final icon = effective.iconColor?.resolve(enabled) ?? foreground;
    return effective.copyWith(
      backgroundColor: background == null
          ? null
          : WidgetStatePropertyAll(background),
      foregroundColor: foreground == null
          ? null
          : WidgetStatePropertyAll(foreground),
      iconColor: icon == null ? null : WidgetStatePropertyAll(icon),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}
