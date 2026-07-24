import 'user_data_service.dart';

class MediaUrlResolver {
  const MediaUrlResolver._();

  static Future<String> resolve(String mediaUrl) async {
    final proxyUrl = await UserDataService.getM3u8ProxyUrl();
    if (proxyUrl.isEmpty) {
      return mediaUrl;
    }
    return '$proxyUrl${Uri.encodeComponent(mediaUrl)}';
  }
}
