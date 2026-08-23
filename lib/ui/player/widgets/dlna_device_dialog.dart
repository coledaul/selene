import 'dart:async';

import 'package:flutter/material.dart';
import 'package:selene/domain/models/dlna_device.dart';
import 'package:selene/ui/player/view_models/dlna_cast_view_model.dart';
import 'package:selene/utils/result.dart';

typedef DlnaDeviceConnector =
    Future<Result<void>> Function(DiscoveredDlnaDevice device);

/// 发现并选择局域网 DLNA 设备的播放器对话框。
class DLNADeviceDialog extends StatefulWidget {
  final DlnaDeviceConnector onConnect;
  final ValueChanged<DiscoveredDlnaDevice>? onCastStarted;
  final DiscoveredDlnaDevice? currentDevice;
  final RecentDlnaDevice? recentDevice;
  final DlnaCastViewModel castViewModel;

  const DLNADeviceDialog({
    super.key,
    required this.onConnect,
    this.onCastStarted,
    this.currentDevice,
    this.recentDevice,
    required this.castViewModel,
  });

  @override
  State<DLNADeviceDialog> createState() => _DLNADeviceDialogState();
}

class _DLNADeviceDialogState extends State<DLNADeviceDialog> {
  bool _isConnecting = false;
  int _connectionGeneration = 0;

  Map<String, DiscoveredDlnaDevice> get _devices =>
      widget.castViewModel.devices;
  bool get _isScanning => widget.castViewModel.scanning;
  String get _scanStatus => widget.castViewModel.scanStatus;

  @override
  void initState() {
    super.initState();
    widget.castViewModel.addListener(_handleCastStateChanged);
    unawaited(widget.castViewModel.startScanning());
  }

  @override
  void dispose() {
    _connectionGeneration++;
    widget.castViewModel.removeListener(_handleCastStateChanged);
    unawaited(widget.castViewModel.stopScanning());
    super.dispose();
  }

  void _handleCastStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshScanning() async {
    await widget.castViewModel.refreshScanning();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 平板模式下使用更小的宽度比例
    final isTablet = screenWidth >= 600;
    final dialogWidth = isTablet
        ? screenWidth *
              0.5 // 平板：50%
        : screenWidth * 0.9; // 手机：90%

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择投屏设备',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 扫描状态
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.wifi_find,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scanStatus,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (!_isScanning)
                    TextButton(
                      onPressed: _refreshScanning,
                      child: const Text('重新扫描'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(child: _buildDeviceSections()),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSections() {
    return ListView(
      children: <Widget>[
        if (widget.recentDevice != null) ...[
          Text('最近使用', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildRecentDeviceTile(),
          const SizedBox(height: 8),
          Text('全部设备', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
        ],
        if (_devices.isEmpty)
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isScanning ? '正在搜索设备...' : '未发现DLNA设备',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!_isScanning) ...[
                    const SizedBox(height: 8),
                    Text(
                      '请确保设备与手机在同一网络下',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ..._devices.values.map(
            (device) => _buildDeviceTile(
              key: ValueKey<String>('device-${device.endpoint}'),
              device: device,
              name: device.friendlyName,
              statusText: '活跃时间: ${_formatTime(device.activeTime)}',
            ),
          ),
      ],
    );
  }

  Widget _buildRecentDeviceTile() {
    final recent = widget.recentDevice!;
    final matches = _devices.values.where(
      (device) => recent.matchesEndpoint(device.endpoint),
    );
    final device = matches.isEmpty ? null : matches.first;
    return _buildDeviceTile(
      key: const ValueKey<String>('recent-device'),
      device: device,
      name: recent.friendlyName,
      statusText: device == null
          ? (_isScanning ? '正在查找设备...' : '当前未发现')
          : '活跃时间: ${_formatTime(device.activeTime)}',
    );
  }

  Widget _buildDeviceTile({
    required Key key,
    required DiscoveredDlnaDevice? device,
    required String name,
    required String statusText,
  }) {
    final isCurrentDevice = device != null && _isCurrentDevice(device);
    final enabled = device != null && !isCurrentDevice && !_isConnecting;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: isCurrentDevice
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : BorderSide.none,
    );
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isCurrentDevice
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(
            _getDeviceIcon(name),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              if (isCurrentDevice)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '当前设备',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            statusText,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          onTap: enabled ? () => _showConnectionDialog(device) : null,
          enabled: enabled,
        ),
      ),
    );
  }

  bool _isCurrentDevice(DiscoveredDlnaDevice device) {
    final current = widget.currentDevice;
    if (current == null) return false;
    return current.matchesEndpoint(device.endpoint);
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('tv') || name.contains('电视')) {
      return Icons.tv;
    } else if (name.contains('box') || name.contains('盒子')) {
      return Icons.device_hub;
    } else if (name.contains('player') || name.contains('播放器')) {
      return Icons.play_circle_outline;
    } else {
      return Icons.devices_other;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }

  Future<void> _showConnectionDialog(DiscoveredDlnaDevice device) async {
    if (_isConnecting) return;
    final generation = ++_connectionGeneration;
    setState(() => _isConnecting = true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('投屏'),
            content: Text('正在投屏到 ${device.friendlyName}...'),
          ),
        ),
      ),
    );

    Result<void> result;
    try {
      result = await widget.onConnect(device);
    } catch (error, stackTrace) {
      result = FailureResult<void>(
        AppFailure(
          kind: FailureKind.platform,
          message: '投屏失败，请重试',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
    if (!mounted || generation != _connectionGeneration) return;

    Navigator.of(context).pop();
    if (result.isFailure) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? '投屏失败，请重试'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    widget.onCastStarted?.call(device);
    if (mounted) Navigator.of(context).pop();
  }
}
