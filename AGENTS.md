# Selene

## 项目概述

Selene 是基于 Flutter 与 `media_kit` 的 MoonTV 视频客户端，支持服务端模式和 Base58 本地订阅模式。

- 服务端模式通过统一鉴权客户端访问 MoonTV API。
- 本地模式直接访问订阅中的搜索源和直播源。
- 播放记录、收藏和搜索历史统一通过 `LibraryRepository` 访问服务端或本地存储。
- 视频下载由 FFmpegKit 重封装为 MKV，并通过 `DownloadRepository` 统一管理任务和文件。

## 架构与目录

依赖方向固定为：`View -> ViewModel -> Repository -> Service -> 外部系统`。

- `lib/app/`：应用对象、`AppDependencies` 组合根和会话缓存协调。
- `lib/domain/models/`：领域模型与不可变数据，不依赖 UI 和外部 I/O。
- `lib/data/repositories/`：领域数据入口、缓存、错误映射和恢复策略。
- `lib/data/services/`：HTTP/SSE、存储、文件、FFmpeg 和平台 I/O。
- `lib/ui/<feature>/`：业务 ViewModel 与 View；`lib/ui/core/`：共享 UI、主题和生命周期基类。
- `lib/routing/`：GoRouter 与强类型路由；`lib/utils/`：Result、Command、日志和纯工具。

## 常用命令

在项目根目录执行：

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
bash test/build_sh_android_arm64_test.sh
bash test/build_sh_parallel_failure_test.sh
bash test/ci_config_test.sh
```

修改 Freezed、JSON 或强类型路由后执行 `dart run build_runner build`。不要手工修改 `*.freezed.dart` 和 `*.g.dart`。

`build.sh` 会清理构建目录并执行发布构建。除非用户明确要求，不要将其用于常规验证；运行前先执行 `./build.sh --help`。

## 修改规则

1. 修改前检查 Git 状态，区分 staged/unstaged 改动；检索相关代码、调用链和已有相似实现。
2. 保留用户改动，优先最小完整修改；不顺带重构、格式化或生成无关文件。
3. 未经明确要求，不暂存、提交、推送、重置、切换分支、改写历史或重新生成平台工程。
4. 优先复用现有模型、Repository 和 Service；新增或升级依赖前说明必要性，并保持 `pubspec.lock` 一致。
5. View 只负责渲染、交互和平台生命周期资源，不直接访问 Repository、Service 或具体数据实现。
6. ViewModel 不依赖 `BuildContext`、Widget、路由或 Service 实现；使用不可变 UI State、`Command` 和 Repository 接口。
7. Repository 不横向依赖其他 Repository，不直接使用 Dio/http，也不调用静态 Service；跨领域编排放入 ViewModel 或应用协调器。
8. Service 不依赖 Repository、UI 或路由；网络、解析、存储、播放器和下载失败必须显式返回，不伪造空结果或成功。
9. 应用级资源由 `AppDependencies` 创建和释放；页面级 ViewModel 由页面 State 通过工厂创建并释放；借用对象不得越权释放。
10. View 异步回调更新界面前检查 `mounted`；ViewModel 使用统一生命周期基类，异步请求使用代次防止旧结果覆盖新状态。
11. `AuthRepository` 是唯一会话状态源；身份变化由 `SessionCacheCoordinator` 统一失效身份相关缓存，不在页面重复清理逻辑。
12. 播放记录、收藏和搜索历史使用 `LibraryRepository`；本地订阅使用 `SubscriptionRepository`；平台差异优先复用 `DeviceUtils`。
13. 下载完成文件属于用户数据，不作为缓存清理；媒体 URL、请求头、密码、Cookie、Token、签名口令和私有订阅不得写入日志或源码。

## 代码与测试

1. 遵循 `analysis_options.yaml` 和 Dart 官方格式；注释沿用仓库中文风格，只解释意图、边界和异常。
2. 修复 Bug 时先添加能复现真实调用链的测试，再修复至通过；不能只调整测试规避问题。
3. 纯逻辑优先单元测试，组件交互使用 Widget 测试，跨页面或平台关键流程才使用集成/真机测试。
4. 架构或所有权变更必须运行 `flutter test test/architecture`；鉴权、搜索、播放器和下载变更运行对应定向测试及全量回归。
5. 完成后运行与范围匹配的格式、分析和测试，清理临时文件与未使用导入，并明确说明未执行的验证。

## 文档维护

- `README.md` 只保留项目入口、快速开始和文档链接。
- 稳定架构、配置和开发说明放在 `docs/guide/`，排错过程和阶段性方案不写入长期指南。
- 修改配置、目录职责、命令、平台边界、签名或构建产物时，同步更新对应文档。
