import 'package:permission_handler/permission_handler.dart';

enum UpdateInstallPermission { granted, denied, unavailable }

abstract interface class UpdatePermissionService {
  Future<bool> requestNotificationPermission();
  Future<UpdateInstallPermission> ensureInstallPermission();
}

final class AndroidUpdatePermissionService implements UpdatePermissionService {
  const AndroidUpdatePermissionService();

  @override
  Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  @override
  Future<UpdateInstallPermission> ensureInstallPermission() async {
    var status = await Permission.requestInstallPackages.status;
    if (status.isGranted) {
      return UpdateInstallPermission.granted;
    }
    status = await Permission.requestInstallPackages.request();
    return status.isGranted
        ? UpdateInstallPermission.granted
        : UpdateInstallPermission.denied;
  }
}

final class UnsupportedUpdatePermissionService
    implements UpdatePermissionService {
  const UnsupportedUpdatePermissionService();

  @override
  Future<UpdateInstallPermission> ensureInstallPermission() async =>
      UpdateInstallPermission.unavailable;

  @override
  Future<bool> requestNotificationPermission() async => false;
}
