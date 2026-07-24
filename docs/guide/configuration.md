# 配置说明

Selene 当前没有 `.env` 配置体系。运行模式和应用设置由界面配置，并通过 SharedPreferences 保存在本机。

## 运行模式

### 服务端模式

登录页需要填写：

| 字段 | 说明 |
| --- | --- |
| 服务端 URL | 可访问的 MoonTV 服务端地址，应用会请求 `/api/login` 等接口。 |
| 用户名 | MoonTV 用户名。 |
| 密码 | MoonTV 密码，用于登录和自动登录。 |

登录成功后，应用保存服务端地址、用户名、密码和 Cookie。当前实现使用 SharedPreferences，不应将其视为安全凭据存储。

### 本地模式

在登录页连续点击 Logo 10 次可切换本地模式，再填写可访问的订阅 URL。

订阅响应应为 Base58 编码的 JSON，可包含：

```json
{
  "api_site": {
    "source_key": {
      "key": "source_key",
      "name": "资源名称",
      "api": "https://example.com/api.php/provide/vod/",
      "detail": "",
      "from": ""
    }
  },
  "lives": {
    "live_key": {
      "key": "live_key",
      "name": "直播源名称",
      "url": "https://example.com/live.m3u",
      "ua": "",
      "epg": "",
      "from": ""
    }
  }
}
```

`api_site` 与 `lives` 至少应有一项包含有效内容。更换订阅 URL 时，应用会询问是否清除原本地模式数据。

## 应用设置

设置入口位于用户菜单。

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| 豆瓣数据源 | 直连 | 控制豆瓣推荐和详情数据的请求来源。 |
| 豆瓣图片源 | 直连 | 控制豆瓣图片 URL 的请求来源。 |
| M3U8 代理 URL | 空 | 为播放地址配置可选代理。 |
| 优选测速 | 开启 | 播放前测试来源并优选播放源。 |
| 本地搜索 | 关闭 | 服务端模式下由客户端直接并发请求搜索源；本地模式始终本地搜索。 |
| 主题 | 跟随系统 | 当前会话可切换；应用重启后恢复跟随系统。 |

豆瓣数据源和图片源包含第三方代理/CDN 选项，其可用性由对应服务决定。

## 本地数据

`UserDataService` 保存连接信息、登录状态和应用设置；`LocalModeStorageService` 保存：

- 订阅 URL、搜索源和直播源；
- 播放记录、收藏和搜索历史。

`DoubanCacheService`、`LocalSearchCacheService` 和 `PageCacheService` 还维护文件或内存缓存。退出登录和清理缓存的影响以界面提示为准。

## 安全边界

- 不要把密钥、密码、Cookie、Token 或私有订阅内容写入源码、文档和日志。
- 订阅与代理地址应使用可信来源，应用会直接访问其中配置的外部服务。
- 当前密码和 Cookie 存储在 SharedPreferences；如改用安全存储，需同时处理旧数据迁移、自动登录和退出清理。
- 客户端配置不能替代服务端鉴权、访问控制和内容安全校验。
