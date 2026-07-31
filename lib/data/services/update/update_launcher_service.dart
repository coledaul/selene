import 'package:url_launcher/url_launcher.dart';

abstract interface class UpdateLauncherService {
  Future<bool> open(Uri uri);
}

final class ExternalUpdateLauncherService implements UpdateLauncherService {
  const ExternalUpdateLauncherService();

  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
