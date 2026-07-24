# Selene

Selene 是基于 Flutter 和 `media_kit` 的 MoonTV 视频客户端，支持 MoonTV 服务端和本地订阅两种运行模式。

主要能力：

- 聚合搜索，以及电影、剧集、动漫、综艺和直播浏览；
- 点播与直播播放、播放源测速、M3U8 代理和 DLNA 投屏；
- 播放记录、收藏、搜索历史和浅色/深色主题；
- Android、iOS、macOS 和 Windows 平台适配代码。

## 快速开始

安装 [Flutter](https://docs.flutter.dev/get-started/install)，然后在项目根目录执行：

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

启动后可连接 MoonTV 服务端。登录页连续点击 Logo 10 次可切换至本地订阅模式。

## 常用检查

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
bash test/build_sh_parallel_failure_test.sh
bash test/ci_config_test.sh
```

## 文档

- [项目概览与目录结构](./docs/guide/overview.md)
- [配置说明](./docs/guide/configuration.md)
- [开发与构建](./docs/guide/development.md)

## 边界

- Selene 是客户端，不包含 MoonTV 服务端。
- 本地模式的数据源和内容由用户配置的订阅提供。
- 根目录 `build.sh` 当前只打包 Android、iOS 和 macOS；其他平台目录不代表已纳入发布流程。
