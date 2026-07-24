# 项目概览与目录结构

## 项目概览

Selene 是使用 Flutter 构建的 MoonTV 视频客户端。

- **播放内核**：`media_kit`，统一承载点播和直播播放。
- **状态管理**：Provider，当前主要用于主题状态。
- **数据访问**：HTTP、SSE，以及本地模式下的下游资源站请求。
- **本地持久化**：SharedPreferences 与内存缓存。
- **运行模式**：MoonTV 服务端模式和 Base58 本地订阅模式。

## 运行模式

### 服务端模式

```text
页面
  -> ApiService / SSESearchService
  -> MoonTV API
  -> 搜索、详情、直播、播放记录、收藏和搜索历史
```

账号登录后，服务端地址、登录信息和 Cookie 由 `UserDataService` 读取。普通接口统一经过 `ApiService`，流式搜索使用 `SSESearchService`。

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

`lib/main.dart` 初始化 `media_kit`、平台窗口和豆瓣缓存。`AppWrapper` 根据运行模式刷新本地订阅或执行服务端自动登录，然后进入首页。

### 页面与导航

`HomeScreen` 组织首页、电影、剧集、动漫、综艺和直播页面。首页内部包含推荐、继续观看、播放历史和收藏；搜索页负责搜索进度与聚合结果。

### 数据服务

- `ApiService`：MoonTV HTTP API、认证请求和统一响应处理。
- `SearchService`：搜索资源管理、本地并发搜索和视频详情解析。
- `SSESearchService`：服务端流式搜索及结果、进度、错误流。
- `SubscriptionService`：解析本地模式的 Base58 订阅。
- `LocalModeStorageService`：本地模式的资源、历史和收藏持久化。
- `PageCacheService`：统一协调本地与服务端的记录类数据。
- `DoubanService` / `BangumiService`：推荐、详情和番剧数据。
- `LiveService`：直播源、频道和 EPG 数据。

### 播放器

`VideoPlayerWidget` 管理 `media_kit` Player、媒体地址、请求头和播放器生命周期。`PlayerScreen` 与 `LivePlayerScreen` 分别负责点播和直播编排，移动端与桌面端使用独立控制组件。

### 平台适配

平台判断集中在 `DeviceUtils` 和受保护的 `Platform.isXxx` 分支。macOS 使用自定义窗口外观，Windows 使用自定义标题栏和窗口尺寸。

当前 `build.sh` 只发布 Android、iOS 和 macOS。Windows 有平台工程与适配代码，但未纳入该脚本；Linux 和 Web 也未形成当前发布流程，且业务代码包含 `dart:io` 和平台专属 API，发布前需要单独验证。

## 文档职责

- `README.md`：项目入口与快速开始。
- `docs/guide/overview.md`：稳定架构与目录边界。
- `docs/guide/configuration.md`：运行模式与应用配置。
- `docs/guide/development.md`：开发、检查与发布构建。
