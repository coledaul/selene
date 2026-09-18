# 应用入口

`bootstrap.dart` 初始化平台能力后创建 `AppDependencies`，由组合根统一持有业务依赖。

Windows 在 `runApp` 前通过 `windows_window_setup.dart` 配置标题栏、1024×600 初始/最小尺寸与居中；原生 runner 负责第一帧绘制后显示窗口。标题栏交互由 `WindowsTitleBar` 调用 `window_manager`，销毁时移除窗口监听。

macOS 沿用 `macos_window_utils` 管理外观，不执行 Windows 窗口配置。
