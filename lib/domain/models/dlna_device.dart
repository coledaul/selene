import 'package:flutter/foundation.dart';

/// UI 可安全使用的 DLNA 发现快照，不持有设备 SDK 对象。
@immutable
final class DiscoveredDlnaDevice {
  const DiscoveredDlnaDevice({
    required this.id,
    required this.endpoint,
    required this.friendlyName,
    required this.deviceType,
    required this.activeTime,
  });

  final String id;
  final String endpoint;
  final String friendlyName;
  final String deviceType;
  final DateTime activeTime;

  bool matchesEndpoint(String value) =>
      _normalizeEndpoint(endpoint) == _normalizeEndpoint(value);

  RecentDlnaDevice toRecentDevice() => RecentDlnaDevice.fromDiscovered(this);
}

@immutable
final class RecentDlnaDevice {
  const RecentDlnaDevice({
    required this.endpoint,
    required this.friendlyName,
    required this.deviceType,
  });

  final String endpoint;
  final String friendlyName;
  final String deviceType;

  factory RecentDlnaDevice.fromDiscovered(DiscoveredDlnaDevice device) =>
      RecentDlnaDevice(
        endpoint: device.endpoint,
        friendlyName: device.friendlyName,
        deviceType: device.deviceType,
      );

  bool matchesEndpoint(String value) =>
      _normalizeEndpoint(endpoint) == _normalizeEndpoint(value);

  Map<String, String> toJson() => <String, String>{
    'endpoint': endpoint,
    'friendlyName': friendlyName,
    'deviceType': deviceType,
  };

  static RecentDlnaDevice? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final endpoint = value['endpoint'];
    final friendlyName = value['friendlyName'];
    final deviceType = value['deviceType'];
    if (endpoint is! String ||
        endpoint.trim().isEmpty ||
        friendlyName is! String ||
        friendlyName.trim().isEmpty ||
        deviceType is! String) {
      return null;
    }
    return RecentDlnaDevice(
      endpoint: endpoint.trim(),
      friendlyName: friendlyName.trim(),
      deviceType: deviceType.trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentDlnaDevice &&
          _normalizeEndpoint(endpoint) == _normalizeEndpoint(other.endpoint) &&
          friendlyName == other.friendlyName &&
          deviceType == other.deviceType;

  @override
  int get hashCode =>
      Object.hash(_normalizeEndpoint(endpoint), friendlyName, deviceType);
}

/// 一次远程播放状态读取的不可变快照。
@immutable
final class DlnaPlaybackSnapshot {
  const DlnaPlaybackSnapshot({
    required this.position,
    required this.duration,
    required this.playing,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
}

String _normalizeEndpoint(String value) {
  final trimmed = value.trim();
  var end = trimmed.length;
  while (end > 0 && trimmed.codeUnitAt(end - 1) == 0x2f) {
    end--;
  }
  return trimmed.substring(0, end);
}
