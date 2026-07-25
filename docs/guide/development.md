# 开发与构建

## 环境准备

- 安装 Flutter stable，并满足 `pubspec.yaml` 中 Dart `>=3.4.3 <4.0.0` 的约束。
- Android 构建需要 Android SDK；iOS 和 macOS 构建需要 macOS 与 Xcode。
- 当前 Android 工具链基线为 Gradle 8.14、Android Gradle Plugin 8.11.1、Kotlin 2.2.20 和 NDK 29。
- 鉴权使用 Dio 5.10、内存 CookieJar 和 `flutter_secure_storage` 10.3.1；Android 最低 API 24 满足安全存储 API 23+ 的要求。
- 视频下载依赖社区预编译的 `ffmpeg_kit_flutter_new_full` LGPL 变体：Android 最低 API 24、iOS 最低 14.0、macOS 最低要求由当前工程的 11.0 满足。
- 使用仓库现有 `pubspec.lock`，不要混入其他依赖管理方式。

获取依赖：

```bash
flutter pub get
```

## 本地运行

```bash
flutter devices
flutter run -d <device-id>
```

常见设备参数由本机 Flutter 环境决定，例如 `android`、iOS Simulator、`macos` 或 `windows`。

## 格式化与检查

检查格式但不修改文件：

```bash
dart format --output=none --set-exit-if-changed lib test
```

需要格式化时：

```bash
dart format lib test
```

静态分析和 Flutter 测试：

```bash
flutter analyze
flutter test
flutter test test/auth_session_controller_test.dart test/auth_network_test.dart
flutter test test/api_service_test.dart test/login_screen_test.dart
flutter test test/video_download_test.dart
```

构建脚本测试：

```bash
bash test/build_sh_parallel_failure_test.sh
bash test/ci_config_test.sh
```

Shell 测试只验证构建失败传播和平台配置，不替代业务单元测试、Widget 测试或集成测试。修复 Bug 时应先增加能复现问题的最小测试。

## FFmpegKit 构建说明

- Dart 包来自 pub；Android 原生预编译库由 Maven Central 解析，Apple 和 Windows 构建会按插件脚本从其 GitHub Release 获取对应预编译产物。首次平台构建必须能访问这些来源。
- 下载实现只使用参数数组调用 FFmpeg/FFprobe，不拼接 shell 命令；媒体 URL、请求头和查询参数不得写入日志或错误文案。
- 默认命令以 `-c copy` 输出 Matroska，仅改变封装而不重新编码，并使用 FFmpeg 自动流选择处理 HLS master playlist。新增转码或 GPL 编码器前必须单独评估包体、性能、专利与许可证。
- 应用内“开源许可”入口展示依赖许可证。发布包应保留 Flutter 生成的许可证材料，并复核 FFmpeg、FFmpegKit 及其编译库的分发要求。
- 下载任务和文件是业务数据，不应由缓存清理器处理；临时 `.part` 文件只能在任务恢复、取消、失败或删除路径中清理。

## 发布构建

查看脚本帮助：

```bash
./build.sh --help
```

可用参数：

| 参数 | 作用 |
| --- | --- |
| `--android-only` | 构建 Android ARM64 与 ARMv7 APK。 |
| `--android-arm64-only` | 仅构建 Android ARM64 APK。 |
| `--ios-only` | 构建无签名 iOS IPA。 |
| `--macos-arm64-only` | 构建 macOS ARM64 DMG。 |
| `--macos-x86_64-only` | 构建 macOS x86_64 DMG。 |
| `--macos-only` | 构建两种 macOS 架构。 |
| `--apple-only` | 顺序构建 iOS 和 macOS。 |
| `--sequential` | 禁用默认并行构建。 |

例如：

```bash
./build.sh --android-only
./build.sh --android-arm64-only
./build.sh --apple-only
```

仅验证 Android Release 分包时可执行：

```bash
flutter build apk --release --split-per-abi
```

## 构建行为与产物

`build.sh` 会执行 `flutter clean` 和 `flutter pub get`，删除旧的 `ios-build/`、`dist/`、`build-arm64/`、`build-x86_64/`，完成后再清理临时构建目录。运行前应确认没有需要保留的本地产物。

发布文件写入 `dist/`：

```text
selene-<version>-armv8.apk
selene-<version>-armv7a.apk
selene-<version>.ipa
selene-<version>-macos-arm64.dmg
selene-<version>-macos-x86_64.dmg
```

Android Release 使用混淆和 split debug info；iOS 产物不签名；macOS 构建仅能在 macOS 执行。Windows、Linux 和 Web 不在当前脚本的发布范围内。

## 变更验证

按改动范围选择检查：

1. Dart 代码：格式检查、`flutter analyze` 和相关测试。
2. 平台工程：对应平台构建或最小平台验证。
3. 下载模块：运行 `flutter test test/video_download_test.dart`，并以合法自有 HLS/MP4 样本验证下载、取消、重试、重启恢复、离线播放和删除。
4. 鉴权模块：验证记住/不记住、启动恢复、本地模式、并发 401、单次重试、SSE、退出和安全存储失败；测试与日志中不得出现真实凭据。
5. 构建脚本：运行两个 Shell 测试；确需发布时再执行 `build.sh`。
6. 配置、目录或构建行为：同步更新 `README.md` 或 `docs/guide/`。

无法执行的检查应在交付说明中明确列出，不要把未运行的命令描述为已通过。
