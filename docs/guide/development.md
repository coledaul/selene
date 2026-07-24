# 开发与构建

## 环境准备

- 安装 Flutter stable，并满足 `pubspec.yaml` 中 Dart `>=3.4.3 <4.0.0` 的约束。
- Android 构建需要 Android SDK；iOS 和 macOS 构建需要 macOS 与 Xcode。
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
```

构建脚本测试：

```bash
bash test/build_sh_parallel_failure_test.sh
bash test/ci_config_test.sh
```

Shell 测试只验证构建失败传播和平台配置，不替代业务单元测试、Widget 测试或集成测试。修复 Bug 时应先增加能复现问题的最小测试。

## 发布构建

查看脚本帮助：

```bash
./build.sh --help
```

可用参数：

| 参数 | 作用 |
| --- | --- |
| `--android-only` | 构建 Android ARM64 与 ARMv7 APK。 |
| `--ios-only` | 构建无签名 iOS IPA。 |
| `--macos-arm64-only` | 构建 macOS ARM64 DMG。 |
| `--macos-x86_64-only` | 构建 macOS x86_64 DMG。 |
| `--macos-only` | 构建两种 macOS 架构。 |
| `--apple-only` | 顺序构建 iOS 和 macOS。 |
| `--sequential` | 禁用默认并行构建。 |

例如：

```bash
./build.sh --android-only
./build.sh --apple-only
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
3. 构建脚本：运行两个 Shell 测试；确需发布时再执行 `build.sh`。
4. 配置、目录或构建行为：同步更新 `README.md` 或 `docs/guide/`。

无法执行的检查应在交付说明中明确列出，不要把未运行的命令描述为已通过。
