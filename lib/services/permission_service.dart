import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:listen_repeat/core/utils/logger.dart';

class PermissionService {
  Future<bool> requestMicrophonePermission() async {
    final status = await permission_handler.Permission.microphone.status;
    if (status.isGranted) {
      AppLogger.i('Microphone permission already granted');
      return true;
    }
    AppLogger.i('Requesting microphone permission');
    final result = await permission_handler.Permission.microphone.request();
    if (result.isGranted) {
      AppLogger.i('Microphone permission granted');
      return true;
    }
    AppLogger.w('Microphone permission denied');
    return false;
  }

  Future<bool> get isPermanentlyDenied async =>
      await permission_handler.Permission.microphone.isPermanentlyDenied;

  Future<void> openAppSettings() =>
      permission_handler.openAppSettings();
}
