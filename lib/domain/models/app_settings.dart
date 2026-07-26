import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('直连') String doubanDataSource,
    @Default('直连') String doubanImageSource,
    @Default('') String m3u8ProxyUrl,
    @Default(true) bool preferSpeedTest,
    @Default(false) bool localSearch,
    @Default('') String appVersion,
  }) = _AppSettings;
}
