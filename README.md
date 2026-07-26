# Selene

Selene 是基于 Flutter 与 `media_kit` 的 MoonTV 视频客户端，支持 MoonTV 服务端和本地订阅两种运行模式。

核心能力：

- 电影、剧集、动漫、综艺、直播与聚合搜索；
- 点播、直播、播放源优选、M3U8 代理与 DLNA 投屏；
- HLS/普通视频下载、任务恢复、下载管理与离线播放；
- 播放记录、收藏、搜索历史、主题和可选的安全登录记忆；
- Android、iOS、macOS 与 Windows 平台适配。

## 快速开始

安装满足项目版本要求的 [Flutter](https://docs.flutter.dev/get-started/install)，在项目根目录执行：

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

应用默认连接 MoonTV 服务端；登录页连续点击 Logo 10 次可进入本地订阅模式。

## 文档

- [项目概览与目录结构](./docs/guide/overview.md)
- [配置说明](./docs/guide/configuration.md)
- [开发与构建](./docs/guide/development.md)

Selene 仅提供客户端。当前发布脚本覆盖 Android、iOS 和 macOS；下载仅支持非 DRM 点播资源。完整平台、配置和构建边界见上述指南。
