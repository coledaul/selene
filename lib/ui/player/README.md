# 播放会话与首帧

本说明涵盖本目录的本地播放会话、首帧判定和显示生命周期。页面业务数据由 ViewModel 编排，播放器及显示资源由 `VideoPlayerWidget` 创建和释放。

## 职责

- [video_playback_session.dart](video_playback_session.dart)：统一播放状态、命令、缓存策略和旧请求隔离。
- [playback_engine.dart](playback_engine.dart)：封装 `media_kit`，选择平台输出检查。
- [playback_first_frame.dart](playback_first_frame.dart)：协调输出通知、就绪检查与 Flutter 帧提交，处理超时和释放取消。
- [native_video_frame_probe.dart](native_video_frame_probe.dart)：Android GPU 视频帧输出检查。
- [video_output_readiness.dart](video_output_readiness.dart)：其他原生平台共用的纹理可用检查。

## 生命周期

- 换源和失败重试时，同时重建会话、`Video` 和对应的 Key，重新绑定视频尺寸等事件。
- 全屏路由借用当前控制器；换会话前退出旧全屏路由，挂载新输出后恢复全屏。
- `Video` 在加载期间保持挂载，让底层能够渲染；加载、错误和重试入口放在共享控制层。
- 首帧等待失败需进入可重试错误态；释放及换源后的迟到结果不能覆盖当前状态。
- 倍速或音量设置失败保留实际值并显示警告，不阻断媒体首帧就绪。

## 平台判定

`media_kit_video 2.0.1` 的首帧通知可能早于实际视频显示，不能单独作为移除加载提示的依据。

| 平台 | 额外检查 |
| --- | --- |
| Android | `gpu` 输出的 `vo-passes/fresh` 非空，且 `core-idle`、`seeking` 为 `no`；保留 `video-latency-hacks=no` |
| iOS、macOS、Windows、Linux | 纹理 ID、视频宽高及纹理尺寸有效，排除 `1×1` 占位纹理 |
| Web | 保留 HTML video 的原有通知路径，不套用原生纹理约定 |

各路径随后等待 Flutter 帧提交。纹理可用不等同于画面已呈现；其他原生平台的 `libmpv` 输出不能直接套用 Android 的 GPU 查询。升级依赖或更改输出后端时，应重新核对这些条件，不用固定延迟或播放进度代替首帧判断。

## 验证

在项目根目录运行：

```bash
flutter test test/ui/player test/architecture
```

在受影响平台实际检查首次播放、续播、换源、切集、错误重试及全屏切换。加载提示应持续到画面出现，失败应保留重试入口；视频内容本身的黑色开头不属于加载故障。自动测试不能替代实际画面验收，验证结果记录在交付说明中。
