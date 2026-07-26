# 项目概览与目录结构

Selene 是 Flutter 构建的 MoonTV 视频客户端。项目采用分层 MVVM：UI 按业务功能组织，Domain 与 Data 按职责分层。

## 架构

```text
View -> ViewModel -> Repository -> Service -> 外部系统
```

| 层 | 职责 | 约束 |
| --- | --- | --- |
| View | 渲染、交互、导航、对话框和页面级 Controller | 不直接访问 Repository 或 Service |
| ViewModel | 管理不可变 `UiState`、`Command` 和页面业务编排 | 不依赖 `BuildContext`，释放后不提交状态 |
| Repository | 提供领域数据入口、缓存、错误映射和恢复策略 | Repository 之间不横向依赖 |
| Service | 封装 HTTP/SSE、存储、文件、FFmpeg 和平台 I/O | 不依赖 UI、路由或 Repository |

`Result<T>` 表达可恢复的成功与失败；Freezed 用于不可变 UI 状态和领域模型。Provider 只负责应用组合与主题监听，不作为业务层服务定位器。

## 组合与所有权

- `bootstrap.dart` 初始化平台组件，`AppDependencies` 是应用级组合根。
- 应用级 Repository、网络客户端、缓存服务和下载管理器由 `AppDependencies` 创建并释放。
- GoRouter 使用强类型路由；页面通过工厂创建并拥有页面级 ViewModel。
- 子组件只借用父级 ViewModel，不释放不属于自己的对象。
- `ViewModel` 基类阻止释放后的状态提交；请求代次负责阻止同一存活对象中的旧请求覆盖新请求。
- Timer、Stream、HTTP Client、播放器和 Controller 必须由创建者释放。

架构测试固定以上依赖方向和所有权边界，防止 UI 反向依赖数据实现或旧目录重新出现。

## 运行模式

### 服务端模式

HTTP 与 SSE 共用 `MoonTvApiClient`、内存 CookieJar 和统一鉴权。多个并发 401 只触发一次重认证，每个可重放请求最多重试一次。播放记录、收藏和搜索历史统一通过 `LibraryRepository` 访问 MoonTV API。

### 本地模式

`SubscriptionRepository` 解析并持久化 Base58 订阅中的搜索源和直播源。搜索、直播、播放记录、收藏与搜索历史继续使用相同 Repository 接口，View 不包含服务端/本地双模式分支。

订阅按完整快照提交。提交成功后，组合根同时失效搜索源列表和本地结果缓存；会话或订阅变化后，旧请求不能重新写入缓存。

## 核心流程

### 会话与缓存

`AuthRepository` 是唯一会话状态源。`SessionCacheCoordinator` 监听登录状态、账号、服务器、角色和运行模式变化，统一失效资料库、直播、搜索源和本地搜索缓存。Library、Live、Search 等 Repository 使用请求代次阻止旧身份响应重新写回。

用户主动“清除缓存”与会话自动失效职责分离：前者同时清除公共内容缓存，后者只处理身份或订阅相关数据。

### 内容与搜索

电影、剧集和综艺复用目录状态机，动漫使用独立配置和相同的 Repository/UI State 模式。分页预取依据剩余滚动距离、视口和网格行高计算。

搜索会话使用单一有序事件流。Repository 统一处理结果、进度、完成、超时和错误；终态后拒绝迟到事件。本地多源搜索隔离单源失败，保留其他可用结果，只有全部源失败才返回失败。

### 播放与下载

`PlayerViewModel` 编排远端详情、播放源优选、收藏、续播、元数据和离线文件；`PlayerRepository` 负责远端播放数据与 URL 解析，用户资料由 `LibraryRepository` 管理，离线文件由 `DownloadRepository` 管理。`media_kit`、DLNA、动画、方向和页面 Controller 属于 View 生命周期。

`DefaultDownloadRepository` 管理持久任务、去重、并发、取消、重试、删除和启动恢复。FFmpeg Service 探测 HLS/普通视频并以流复制方式重封装为 MKV，文件 Service 使用 `.part` 临时文件和原子完成路径。

## 目录结构

```text
Selene-Source/
├── lib/
│   ├── app/                    # 应用对象、依赖组合与会话协调
│   ├── data/
│   │   ├── repositories/       # Repository 接口与默认实现
│   │   └── services/           # 网络、存储、文件、FFmpeg 与平台 I/O
│   ├── domain/models/          # 领域模型与不可变数据
│   ├── routing/                # GoRouter 与强类型路由
│   ├── ui/
│   │   ├── core/               # 主题、布局和共享组件
│   │   ├── auth/               # 登录与启动恢复
│   │   ├── home/               # 首页、历史与收藏
│   │   ├── catalog/            # 电影、剧集、动漫与综艺
│   │   ├── search/             # 搜索会话、筛选与结果
│   │   ├── live/               # 直播列表、频道与 EPG
│   │   ├── player/             # 点播、DLNA 与播放源
│   │   ├── downloads/          # 下载与离线播放
│   │   ├── settings/           # 设置、缓存、更新与退出
│   │   └── shell/              # 主框架、导航与搜索建议
│   ├── utils/                  # Result、Command、日志与纯工具
│   ├── bootstrap.dart          # 平台初始化
│   └── main.dart               # 最小入口
├── test/                       # 单元、Widget、架构与脚本测试
├── docs/guide/                 # 稳定项目指南
├── build.sh                    # 发布构建脚本
└── pubspec.yaml                # 版本、依赖与资源
```

## 平台边界

平台判断集中在 `DeviceUtils` 和受保护的 `Platform.isXxx` 分支。当前发布脚本覆盖 Android、iOS 和 macOS；Windows 有工程与运行适配，但未纳入脚本。Linux 与 Web 不在当前发布流程中。

下载仅支持非 DRM 点播资源；不支持直播下载、字节级断点续传或应用进程被系统终止后的后台持续下载。
