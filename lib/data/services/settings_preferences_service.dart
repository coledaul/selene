import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';

abstract interface class SettingsPreferencesService {
  Future<AppSettings> load();
  Future<void> saveDoubanDataSource(String value);
  Future<void> saveDoubanImageSource(String value);
  Future<void> saveM3u8ProxyUrl(String value);
  Future<void> savePreferSpeedTest(bool value);
  Future<void> saveLocalSearch(bool value);
}

final class SharedPreferencesSettingsService
    implements SettingsPreferencesService {
  static const String _doubanDataSourceKey = 'douban_data_source';
  static const String _doubanImageSourceKey = 'douban_image_source';
  static const String _m3u8ProxyUrlKey = 'm3u8_proxy_url';
  static const String _preferSpeedTestKey = 'prefer_speed_test';
  static const String _localSearchKey = 'local_search';

  @override
  Future<AppSettings> load() async {
    final preferences = SharedPreferencesAsync();
    final packageInfo = await PackageInfo.fromPlatform();
    return AppSettings(
      doubanDataSource: _dataSourceDisplayName(
        await preferences.getString(_doubanDataSourceKey) ?? 'direct',
      ),
      doubanImageSource: _imageSourceDisplayName(
        await preferences.getString(_doubanImageSourceKey) ?? 'direct',
      ),
      m3u8ProxyUrl: await preferences.getString(_m3u8ProxyUrlKey) ?? '',
      preferSpeedTest: await preferences.getBool(_preferSpeedTestKey) ?? true,
      localSearch: await preferences.getBool(_localSearchKey) ?? false,
      appVersion: packageInfo.version,
    );
  }

  @override
  Future<void> saveDoubanDataSource(String value) => SharedPreferencesAsync()
      .setString(_doubanDataSourceKey, _dataSourceKey(value));

  @override
  Future<void> saveDoubanImageSource(String value) => SharedPreferencesAsync()
      .setString(_doubanImageSourceKey, _imageSourceKey(value));

  @override
  Future<void> saveM3u8ProxyUrl(String value) =>
      SharedPreferencesAsync().setString(_m3u8ProxyUrlKey, value.trim());

  @override
  Future<void> savePreferSpeedTest(bool value) =>
      SharedPreferencesAsync().setBool(_preferSpeedTestKey, value);

  @override
  Future<void> saveLocalSearch(bool value) =>
      SharedPreferencesAsync().setBool(_localSearchKey, value);

  String _dataSourceKey(String value) => switch (value) {
    'Cors Proxy By Zwei' => 'cors_proxy',
    '豆瓣 CDN By CMLiussss（腾讯云）' => 'cdn_tencent',
    '豆瓣 CDN By CMLiussss（阿里云）' => 'cdn_aliyun',
    _ => 'direct',
  };

  String _imageSourceKey(String value) => switch (value) {
    '豆瓣官方精品 CDN' => 'official_cdn',
    '豆瓣 CDN By CMLiussss（腾讯云）' => 'cdn_tencent',
    '豆瓣 CDN By CMLiussss（阿里云）' => 'cdn_aliyun',
    _ => 'direct',
  };

  String _dataSourceDisplayName(String key) => switch (key) {
    'cors_proxy' => 'Cors Proxy By Zwei',
    'cdn_tencent' => '豆瓣 CDN By CMLiussss（腾讯云）',
    'cdn_aliyun' => '豆瓣 CDN By CMLiussss（阿里云）',
    _ => '直连',
  };

  String _imageSourceDisplayName(String key) => switch (key) {
    'official_cdn' => '豆瓣官方精品 CDN',
    'cdn_tencent' => '豆瓣 CDN By CMLiussss（腾讯云）',
    'cdn_aliyun' => '豆瓣 CDN By CMLiussss（阿里云）',
    _ => '直连',
  };
}
