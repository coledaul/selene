# 项目概览与目录结构

## 项目概览

Selene 是使用 Flutter 构建的 MoonTV 视频客户端。

- **播放内核**：`media_kit`，统一承载点播和直播播放。
- **状态管理**：Provider，统一提供主题、认证会话、API、缓存与下载服务。
- **数据访问**：Dio 统一承载 MoonTV HTTP、Cookie、401 重认证和 SSE；本地模式直接访问下游资源站。
- **本地持久化**：SharedPreferences 保存普通配置，平台安全存储保存可选密码，Cookie 仅驻留内存，下载文件进入应用私有目录。
- **运行模式**：MoonTV 服务端模式和 Base58 本地订阅模式。

## 运行模式

### 服务端模式

```text
页面
  -> ApiService / SSESearchService
  -> MoonTvApiClient + AuthSessionController
  -> MoonTV API
  -> 搜索、详情、直播、播放记录、收藏和搜索历史
```

`AuthSessionController` 是唯一会话状态来源。`AuthProfileStore` 保存连接资料，`SecureCredentialStore` 保存用户明确允许记住的密码，内存 CookieJar 按标准 Cookie 规则维护当前会话。普通接口和 SSE 共用 `MoonTvApiClient`，网络层不持有页面上下文或执行导航。

### 本地模式

```text
订阅 URL
  -> SubscriptionService
  -> SearchResource / LiveSource
  -> SearchService / LiveService
  -> 下游搜索 API、M3U8 和 EPG
```

订阅响应应为 Base58 编码的 JSON。搜索源、直播源、播放记录、收藏和搜索历史保存在本机，不依赖 MoonTV 服务端。

## 目录结构

```text
Selene-Source/
├── lib/
│   ├── models/                 # 领域数据模型
│   ├── app/                    # 根级依赖组装
│   ├── core/network/           # Dio、Cookie 与 401 重认证
│   ├── features/               # 按业务聚合的独立功能模块
│   ├── screens/                # 登录、首页、搜索、分类和播放器页面
│   ├── services/               # API、搜索、订阅、缓存和本地存储
│   ├── utils/                  # 平台与展示工具
│   ├── widgets/                # 公共 UI、播放器控件和内容组件
│   └── main.dart               # 应用初始化与启动导航
├── android/                    # Android 平台工程
├── ios/                        # iOS 平台工程
├── macos/                      # macOS 平台工程
├── windows/                    # Windows 平台工程
├── linux/                      # Linux 平台工程
├── web/                        # Web 平台工程
├── test/                       # 自动化测试
├── build.sh                    # Android 与 Apple 平台发布脚本
└── pubspec.yaml                # Dart SDK、依赖、资源和版本配置
```

## 关键模块

### 应用入口

`lib/main.dart` 初始化 `media_kit`、平台窗口和豆瓣缓存，并通过 `AppDependencies` 组装应用级服务。`AppWrapper` 根据认证状态创建独立 Navigator；登录失效、退出或切换模式时会销毁旧页面栈。

### 页面与导航

`HomeScreen` 组织首页、电影、剧集、动漫、综艺和直播页面。首页内部包含推荐、继续观看、播放历史和收藏；搜索页负责搜索进度与聚合结果。

### 数据服务

- `features/auth/`：连接资料、安全凭据、登录状态机、自动登录和单航班重认证。
- `core/network/`：Dio 客户端、内存 CookieJar、认证登录与 401 单次重试。
- `ApiService`：可注入的 MoonTV 业务 API 门面与统一响应转换，不处理导航。
- `SearchService`：搜索资源管理、本地并发搜索和视频详情解析。
- `SSESearchService`：服务端流式搜索及结果、进度、错误流。
- `SubscriptionService`：解析本地模式的 Base58 订阅。
- `LocalModeStorageService`：本地模式的资源、历史和收藏持久化。
- `PageCacheService`：统一协调本地与服务端的记录类数据。
- `DoubanService` / `BangumiService`：推荐、详情和番剧数据。
- `LiveService`：直播源、频道和 EPG 数据。

### 播放器

`VideoPlayerWidget` 管理 `media_kit` Player、媒体地址、请求头和播放器生命周期。`PlayerScreen` 与 `LivePlayerScreen` 分别负责点播和直播编排，移动端与桌面端使用独立控制组件。

### 视频下载

`lib/features/video_download/` 是独立下载模块：

- `domain/` 定义稳定任务身份、状态与持久化模型；
- `application/` 负责单任务队列、去重、进度、取消、重试、删除和启动恢复；
- `infrastructure/` 通过 FFmpegKit 处理 HLS/普通视频探测与 MKV 无损重封装，并管理临时文件和最终文件；
- `presentation/` 提供分集多选、下载管理和本地播放页面。

播放地址代理由 `MediaUrlResolver` 统一处理。点播时会先按“来源 + 内容 ID + 集数”查找已完成文件，命中后直接交给现有 `media_kit` 播放器；投屏仍使用远程地址。

任务异常中断后会在下次启动清理半成品并重新排队。当前不伪装成字节级断点续传，也不支持暂停、直播或 DRM。

### 平台适配

平台判断集中在 `DeviceUtils` 和受保护的 `Platform.isXxx` 分支。macOS 使用自定义窗口外观，Windows 使用自定义标题栏和窗口尺寸。

当前 `build.sh` 只发布 Android、iOS 和 macOS。Windows 有平台工程与适配代码，但未纳入该脚本；Linux 和 Web 也未形成当前发布流程，且业务代码包含 `dart:io` 和平台专属 API，发布前需要单独验证。

## 文档职责

- `README.md`：项目入口与快速开始。
- `docs/guide/overview.md`：稳定架构与目录边界。
- `docs/guide/configuration.md`：运行模式与应用配置。
- `docs/guide/development.md`：开发、检查与发布构建。
