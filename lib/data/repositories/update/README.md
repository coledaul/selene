# Android 应用更新模块

Android 在应用内下载并校验 APK，再交给系统安装器；Windows、macOS 和 iOS 通过浏览器打开 Release 页面。

## 调用方向

```text
UpdateDialog -> UpdateViewModel -> UpdateRepository
                                   -> UpdateTransferController -> Update Service
```

- `update_repository.dart`：版本检查、提示策略和统一入口。
- `update_transfer_controller.dart`：下载、恢复、校验与安装状态管理。
- `update_download_plan.dart`：生成下载任务与线路回退计划，不执行 I/O。
- `pending_update_action.dart`：等待插件确认暂停或恢复，隔离请求接受与实际生效。
- `../../services/update/`：网络、后台下载、文件、权限与存储适配。
- `../../../ui/update/`：弹窗与页面状态，不直接访问插件或文件。

## 关键规则

- 每次冷启动自动检查一次；关闭弹窗只结束本次提示，忽略按版本保存。手动检查始终可用，不受忽略设置影响。
- 检查与下载均优先使用 `gh-proxy.com`，失败后回退 GitHub 直连。检查失败含响应无效，直连只请求一次；下载首选线路不重试，恢复任务沿用原请求。
- 仅接受固定仓库中与当前 ARM ABI 唯一匹配的正式 APK；无法匹配或校验元数据时，仅提供 Release 页面入口。
- APK 存放于 `applicationSupport/updates/`，安装前必须校验大小与 SHA-256。代理同时转发元数据和文件，校验不等同于独立的发布者认证。
- 不申请公共存储权限，不持久化认证头、Cookie、Token 或私有地址。
- 失败通过 `Result` 或 `UpdateTransferPhase.failed` 返回；拉起安装器不代表安装成功。
- 下载操作互斥，暂停前检查可续传能力；状态事件串行处理，不用状态通知重置进度。每次重下载使用独立任务标识，旧回调不能覆盖新任务。
- 冷恢复使用插件实际确认并保存的续传能力；旧任务无记录时保留下载，不冒险暂停。续传失败仍可取消后重下或使用浏览器。

## 修改与验证

```bash
flutter test test/data/update test/ui/update test/architecture
```

发布前真机覆盖 Android 7、Android 8+、arm64/armv7 及国产定制系统，验证未知来源授权、通知拒绝、后台恢复和安装器取消；交付时注明未验证项。
