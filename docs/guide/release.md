# 发布指南

Selene 的正式发布已经自动化。以后发布新版本不需要手动构建或上传 APK、ZIP、DMG，也不需要配置静态文件服务器。

## 相关文件

- [ci.yml](../../.github/workflows/ci.yml#L1)：`main` push 和 Pull Request 的格式、分析与测试。
- [release.yml](../../.github/workflows/release.yml#L1)：版本标签触发的多平台构建和 GitHub Release 发布。
- [build.sh](../../build.sh#L1)：Android、无签名 iOS 和 macOS Universal DMG 的本地发布构建。
- [prepare_windows_ffmpeg.ps1](../../scripts/prepare_windows_ffmpeg.ps1#L1)：准备并校验 Windows FFmpegKit 依赖。
- [verify_android_release.sh](../../scripts/verify_android_release.sh#L1)：验证 Android APK 签名证书。
- [extract_release_notes.sh](../../scripts/extract_release_notes.sh#L1)：从 `CHANGELOG.md` 提取指定正式版本的发布说明。
- [development.md](./development.md)：开发环境、测试和交付检查。
- [pubspec.yaml](../../pubspec.yaml#L1)：应用版本。
- [CHANGELOG.md](../../CHANGELOG.md#L1)：正式版本更新记录。

## Android 签名配置

本地 Android 构建读取被 Git 忽略的 `android/key.properties`。存在该文件时使用项目自己的 Release keystore；不存在时会回退到 Debug 签名，即使构建类型仍为 `release`。该回退仅用于本地开发，CI 中执行 Release 任务但缺少显式签名配置会直接失败。

`key.properties` 使用以下字段，真实值只保存在开发者本机：

```properties
storeFile=/absolute/path/to/selene-release.jks
storePassword=<store-password>
keyAlias=<key-alias>
keyPassword=<key-password>
```

不要提交 `key.properties`、`.jks`、`.keystore` 或任何口令。维护同一发布分支时必须持续使用同一 keystore；更换签名后，Android 会把它视为不同签名的应用，不能直接覆盖安装旧版本。

GitHub Actions 使用以下仓库配置：

| 类型 | 名称 | 内容 |
| --- | --- | --- |
| Actions Secret | `ANDROID_KEYSTORE_BASE64` | Release keystore 的单行 Base64 内容 |
| Actions Secret | `ANDROID_STORE_PASSWORD` | keystore 密码 |
| Actions Secret | `ANDROID_KEY_ALIAS` | Release key alias |
| Actions Secret | `ANDROID_KEY_PASSWORD` | Release key 密码 |
| Actions Variable | `ANDROID_SIGNING_CERT_SHA256` | 预期签名证书 SHA-256，可含冒号且不区分大小写 |

Release workflow 会在一次性 runner 中恢复 keystore，构建后验证每个 APK 的签名证书。任一配置缺失、APK 数量不符或证书不匹配都会终止发布；日志不得输出 Secret 或 keystore 内容。

## 本地发布构建

`build.sh` 会执行 `flutter clean`、严格按 `pubspec.lock` 获取依赖、删除旧 `dist/` 和 Apple 临时目录，并在完成后清理 `build/`。它不应作为日常验证命令；运行前先查看帮助并确认没有需要保留的本地产物。

```bash
./build.sh --help
```

| 参数 | 作用 |
| --- | --- |
| `--android-arm64-only` | 仅构建 Android ARM64 APK。 |
| `--android-only` | 构建 Android ARM64 与 ARMv7 APK。 |
| `--ios-only` | 构建无签名 iOS IPA。 |
| `--macos-only` | 构建并用 `lipo` 验证 macOS Universal DMG。 |
| `--apple-only` | 顺序构建 iOS 与 macOS。 |
| `--sequential` | 禁用默认并行构建。 |

无参数时脚本尝试构建全部已支持目标；iOS 和 macOS 只能在 macOS 上构建。产物写入 `dist/`：

```text
selene-<version>-armv8.apk
selene-<version>-armv7a.apk
selene-<version>.ipa
selene-<version>-macos-universal.dmg
```

iOS IPA 不签名；macOS DMG 要求主可执行文件同时包含 `arm64` 和 `x86_64`，但当前未做 Developer ID 签名或公证。Windows 由 Release workflow 单独构建，不在 `build.sh` 范围内。

## 自动化发布

普通 CI 同时作为正式发布的自动质量门禁：

- `ci.yml` 在 `main` push 和 Pull Request 上运行，也可由 Release 复用；它只具有 `contents: read` 权限，不接触签名 Secret。
- `release.yml` 仅由 `vMAJOR.MINOR.PATCH` 标签触发，要求标签版本与 `pubspec.yaml` 一致、标签提交已经包含在 `main` 中，并在构建前自动等待同一套 CI 检查通过。
- GitHub Release 说明取自 `CHANGELOG.md` 中对应的正式版本；版本段落缺失或为空时停止发布，客户端与发布页使用同一份内容。
- 自动产物为两个已验证签名的 Android APK、Windows x64 便携版、macOS Universal DMG 和 `SHA256SUMS.txt`。
- workflow 先创建 Draft Release，上传并核对全部五个资产后才公开为 Latest；任何构建或校验失败都会阻止不完整版本发布。
- iOS 无签名 IPA 不进入自动 Release。

所有第三方 Action 都固定到完整 commit SHA。更新 Action 时应核对上游发布说明与 commit，不得改回浮动的 `@main`。

## 社区贡献

- Pull Request 合并不会发布版本，只有维护者推送正式标签后才会启动 Release。
- 贡献者在 PR 模板中填写用户可见变化；维护者合并时负责整理到 `CHANGELOG.md` 顶部的待发布版本。
- 测试、CI、文档和无用户影响的重构不必写入更新日志；外部贡献可在最终条目中标注 PR 与贡献者。

## 发布新版本

以后发布新版本只需要：

1. 更新 `pubspec.yaml` 中的版本，例如 `1.8.3+2163`。
2. 确认 `CHANGELOG.md` 顶部的待发布版本号，并将 `未发布` 改为正式发布日期。
3. 完成与改动范围匹配的本地检查，正常提交并推送到 `main`。
4. 在同一提交上创建与 `pubspec.yaml` 一致的标签并推送：

```bash
version="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' pubspec.yaml)"
git tag -a "v$version" -m "Selene v$version"
git push origin "v$version"
```

不需要人工等待普通 CI；标签推送后，Release workflow 会自动运行同一套 CI 门禁，通过后再构建、校验并发布全部安装包。不得在签名 Secrets、证书摘要或 `main` 祖先关系尚未配置或验证时推送正式标签。
