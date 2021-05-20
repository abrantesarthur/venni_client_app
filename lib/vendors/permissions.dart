import 'package:permission_handler/permission_handler.dart';

class _AppPermission {
  static Future<bool> _requestPermission(Permission resource) async {
    // check camera permission
    PermissionStatus status = await resource.status;

    // if permission was permanently denied
    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      // ask user to update permission in App settings
      bool settingsOpened = await openAppSettings();
      if (!settingsOpened) {
        // if the user did not open settings, return false
        return false;
      }
      // try again
      return _requestPermission(resource);
    }

    // request permission
    status = await resource.request();

    if (status == PermissionStatus.granted) {
      return true;
    }

    return false;
  }
}

class Camera {
  static Future<bool> requestPermission() async {
    return await _AppPermission._requestPermission(Permission.camera);
  }
}
