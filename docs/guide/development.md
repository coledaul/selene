# 开发与构建

## 环境要求

| 平台 | 当前基线 |
| --- | --- |
| Flutter / Dart | Flutter `>=3.44.0`，Dart `>=3.12.0 <4.0.0` |
| Android | minSdk 24、AGP 8.11.1、Kotlin 2.2.20、NDK 29.0.14033849 |
| iOS | iOS 14.0，macOS 与 Xcode |
| macOS | macOS 11.0，macOS 与 Xcode |
| Windows | 有工程与运行适配，不在 `build.sh` 发布范围内 |

使用 Flutter stable 和仓库现有 `pubspec.lock`。首次平台构建需要访问 pub、Maven Central，以及 FFmpegKit 插件声明的 Apple/Windows 预编译产物来源。

项目在 Flutter 3.44 上启用 Swift Package Manager；支持 SwiftPM 的 Apple 插件使用 SwiftPM，其余插件由 Flutter 回退到 CocoaPods。不要重新关闭该配置，否则仅提供 SwiftPM 清单的插件会阻止 iOS/macOS 构建。

```bash
flutter doctor -v
flutter pub get
```

## 本地运行

先查看 Flutter 识别的设备，再使用设备 ID 运行：

```bash
flutter devices
flutter run -d <device-id>
```

Android 模拟器常见形式为：

```bash
flutter run -d emulator-5554
```

开发运行使用 Debug 构建，不需要执行 `build.sh`。iOS Simulator 停止构建后会保留 Flutter、Dart、Pods 和 Xcode 的常规增量缓存；`flutter clean` 才会清除项目构建缓存。

## 代码生成

修改 Freezed 模型、JSON 序列化模型或强类型路由后执行：

```bash
dart run build_runner build
```

生成文件必须与源文件一起更新。不要手工修改 `*.freezed.dart`、`*.g.dart`；出现生成冲突时先确认源文件和工作区状态，不直接覆盖不明改动。

## 格式、分析与测试

常规完整检查：

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
bash test/build_sh_android_arm64_test.sh
bash test/build_sh_parallel_failure_test.sh
bash test/ci_config_test.sh
```

需要格式化时执行：

```bash
dart format lib test
```

按改动范围运行定向测试，例如：

```bash
flutter test test/architecture
flutter test test/auth_session_controller_test.dart test/auth_network_test.dart
flutter test test/api_service_test.dart test/login_screen_test.dart
flutter test test/video_download_test.dart
```

三项 Shell 测试分别验证 Android ARM64 参数/产物、并行失败传播和平台构建配置；它们不替代 Dart 单元测试、Widget 测试或真实设备验证。

## 开发约束

- 保持 `View -> ViewModel -> Repository -> Service` 依赖方向，Repository 之间不横向依赖。
- ViewModel 使用不可变 UI State 和 `Command`；View 只管理界面与平台生命周期资源。
- 应用级资源由 `AppDependencies` 释放，页面级资源由创建它的 State 释放，借用对象不得越权关闭。
- 网络、存储、解析、播放器和下载关键路径必须返回明确错误，不把失败伪装为空结果或成功。
- 修复 Bug 时先增加可复现测试，再修改实现并运行相关测试与全量回归。
- 不在日志、测试夹具或文档中写入真实密码、Cookie、Token、签名口令和私有订阅。

## FFmpegKit

- 下载通过参数数组调用 FFmpeg/FFprobe，不拼接 shell 命令。
- 默认使用 `-c copy` 重封装为 Matroska，不进行视频转码；HLS master playlist 交由 FFmpeg 选择播放流。
- 新增转码、GPL 编码器或新的二进制变体前，必须评估包体、性能、专利和分发许可证。
- 媒体 URL、请求头和查询参数不得写入日志或错误文案。
- 下载任务和文件是业务数据；缓存清理器不得删除完成文件，`.part` 仅在恢复、取消、失败或删除路径中清理。

## 发布

签名配置、本地发布构建、自动化发布和版本标签流程见[发布指南](./release.md)。

## 交付检查

1. Dart 代码：格式检查、静态分析、相关测试和全量测试。
2. 架构变更：运行 `flutter test test/architecture`，确认依赖方向与所有权契约。
3. 鉴权变更：验证记住/不记住、启动恢复、本地模式、并发 401、单次重试、退出和安全存储失败。
4. 下载变更：使用合法自有 HLS/MP4 样本验证下载、取消、重试、恢复、离线播放和删除。
5. 平台工程：运行对应平台的最小构建或真机验证。
6. 发布相关修改：运行三项 Shell 测试；本地打包与标签流程见[发布指南](./release.md)。
7. 配置、目录、命令或产物变化：同步更新 README 或对应指南。

无法执行的检查必须在交付说明中列出，不得把未运行的命令描述为已通过。
