# Android 应用更新模块

本模块负责将 GitHub Release 中可信的 Android APK 下载到应用私有目录，完成完整性校验后交给系统安装器。Windows、macOS 和 iOS 继续打开 Release 页面。

## 调用方向

```text
UpdateDialog -> UpdateViewModel -> UpdateRepository
                                   -> UpdateTransferController -> Update Service
```

- `update_repository.dart`：版本检查、提示策略、下载线路偏好和 UI 统一入口。
- `update_transfer_controller.dart`：下载、回退、恢复、校验、权限和安装器交付状态机。
- `update_download_plan.dart`：纯逻辑生成确定性任务 ID、重试策略和有序线路请求。
- `../../services/update/`：GitHub API、后台下载插件、文件校验、权限、外部链接和偏好存储适配。
- `../../../ui/update/`：更新对话框及其页面级状态适配，不直接访问插件或文件系统。

## 稳定合同

- GitHub Release API 是版本、资产大小和 SHA-256 的权威来源；`gh-proxy.com` 只作为字节传输线路。
- 自动线路固定先使用加速地址，失败后回退 GitHub 直连；首选线路不重复重试，避免用户在不可用地址上长时间等待。
- 只接受当前 ARM ABI 唯一匹配的正式 APK。资产缺失、重复或元数据不可信时关闭应用内安装，保留 Release 页面入口。
- APK 固定存放在 `applicationSupport/updates/`，不申请公共存储权限，也不持久化认证头、Cookie、Token 或私有地址。
- 下载完成事件不能直接打开 APK；必须先核对实际大小并流式计算 SHA-256。
- 所有插件异常必须转换为 `Result` 或明确的 `UpdateTransferPhase.failed`，不能以未处理异步异常离开 Repository。
- 拉起系统安装器只表示完成文件交付，不代表用户已经安装成功。

## 修改与验证

涉及本模块时至少运行：

```bash
flutter test test/data/update test/ui/update
flutter test test/architecture
```

发布前还需在真机验证 Android 7、Android 8 及以上未知来源授权、通知拒绝、后台恢复、安装器取消、arm64/armv7，以及至少一台常见国产定制系统。无法完成的真机项必须在交付说明中明确列出。
