import 'package:permission_handler/permission_handler.dart';

abstract final class PermissionService {
  static Future<bool> openSettings() => openAppSettings();
}
