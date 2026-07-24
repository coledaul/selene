# Selene

## 项目概述

Selene 是基于 Flutter 和 `media_kit` 的 MoonTV 视频客户端，支持服务端模式与本地订阅模式。

- 服务端模式通过 `ApiService` 访问 MoonTV API。
- 本地模式解析 Base58 订阅，直接访问搜索源和直播源。
- 播放记录、收藏和搜索历史由 `PageCacheService` 统一协调服务端与本地存储。

## 技术栈与目录

- Flutter / Dart、Provider、media_kit、HTTP / SSE、SharedPreferences。
- `lib/models/`：领域数据模型。
- `lib/screens/`：页面与页面级交互。
- `lib/services/`：网络、存储、缓存、搜索和订阅解析。
- `lib/widgets/`：可复用 UI 与播放器组件。
- `lib/utils/`：平台判断等通用工具。

## 常用命令

在项目根目录执行：

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
bash test/build_sh_parallel_failure_test.sh
bash test/ci_config_test.sh
```

`build.sh` 会清理目录并执行发布构建。除非用户明确要求，不要把它作为常规验证命令；使用前先运行 `./build.sh --help`。

## 开发规则

1. 修改前检查 Git 状态，检索相关代码、调用链和已有相似实现。
2. 保留用户已有改动，优先最小范围修改，不顺带重构无关代码。
3. 未经明确要求，不提交、推送、重置、切换分支或重新生成平台工程。
4. 优先复用现有依赖和抽象；新增或升级依赖前说明必要性，并保持 `pubspec.lock` 一致。
5. 服务端请求复用 `ApiService`；本地数据复用 `LocalModeStorageService`。
6. 播放记录、收藏和搜索历史优先通过 `PageCacheService`，不要在页面重复实现双模式分支。
7. 平台差异优先复用 `DeviceUtils`；平台专属能力必须有明确的平台保护。
8. 网络、解析、存储和播放器关键路径必须处理错误与超时，不静默伪造成功。
9. 异步 UI 更新前检查 `mounted`；Controller、Timer、Stream、HTTP client 和播放器必须正确释放。
10. 不硬编码或输出密钥、密码、Cookie、Token 和私有订阅内容。

## 代码与测试

1. 遵循 `analysis_options.yaml` 和 Dart 官方格式化，不另设冲突风格。
2. 注释沿用仓库现有中文风格，只说明意图、边界和异常。
3. 保持模块职责清晰；页面负责交互与装配，数据访问和可复用逻辑放入对应 service 或 widget。
4. 修复 Bug 时先补复现测试，再修复至通过。
5. 普通逻辑优先单元测试，组件交互使用 Widget 测试，关键完整流程才使用集成测试。
6. 完成后运行与改动范围匹配的格式化、静态分析和测试，并说明未验证项。

## 文档维护

- `README.md` 只保留项目入口、快速开始和文档链接。
- 稳定说明放在 `docs/guide/`，阶段性方案不要混入长期指南。
- 修改配置、目录职责、运行命令、平台边界或构建产物时，同步更新对应文档。
