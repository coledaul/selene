# 应用主题

沿用绿色强调色、中性表面与现有控件风格，不在业务模块建立独立主题。

- `app_theme.dart`：唯一入口，定义浅深色语义配色并组合主题，由 `SeleneApp` 注入。
- `app_tokens.dart`：品牌色、圆角与常规触控尺寸。
- `app_typography.dart`：文字层级，复用 `FontUtils` 的 Poppins / Windows 微软雅黑策略。
- `app_component_themes.dart`：按钮、弹窗、菜单、进度等 Material 控件默认样式。
- `app_button_styles.dart`：异步加载与视频遮罩的按钮样式，局部配色优先于主题默认值。

## 使用

- 页面使用 `Theme.of(context).colorScheme`、`textTheme` 和原生控件主题；不重新生成 `ThemeData`。
- 自绘控件中的固定品牌色使用 `AppBrand`；明暗相关颜色使用 `ColorScheme`。
- 弹窗直接继承 `dialogTheme`，业务层只处理内容、尺寸与交互。
- 错误和危险操作保留语义颜色；播放器覆盖层、评分、封面及首页渐变按场景处理，不统一染绿。
- 共用样式在这里修改，业务例外在对应组件注明原因；不为套样式再包装整套控件。

## 按钮状态

| 状态 | 交互与外观 |
| --- | --- |
| 正常、按下、悬停、焦点 | 沿用原生反馈，不自行模拟点击状态。 |
| 不可用 | `onPressed: null`，使用禁用配色；特殊按钮同时定义普通与禁用颜色。 |
| 正在处理 | `onPressed: null`，通过 `AppButtonStyles.filled/elevated(loading: true)` 保持启用态配色，显示进度或明确的等待文字。 |
| 处理结束 | 成功、失败或取消后恢复状态；异步状态仍由原有 ViewModel 或页面持有。 |

按钮内进度使用 `AppButtonProgress` 跟随最终前景色；透明图标操作显式传入前景色。进度替换文字时保留占位，避免尺寸跳动。视频遮罩上的次要按钮使用 `AppButtonStyles.onMedia`，不继承页面明暗配色。

## 验证

```bash
flutter test test/login_screen_test.dart test/ui/core test/ui/update test/ui/downloads test/ui/player test/ui/home test/architecture
```

页面测试必须接入真实 `AppTheme`，检查浅深色、按下/禁用/加载/恢复、小屏横竖屏与大字体。组件测试不替代真机视觉验收。
