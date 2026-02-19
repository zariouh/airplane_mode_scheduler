import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'; // ADD THIS IMPORT
import '../services/airplane_mode_service.dart';
import '../utils/logger.dart';

class PermissionProvider extends StateNotifier<PermissionStatus> {
  PermissionProvider() : super(PermissionStatus());

  // Check all permissions
  Future<bool> checkPermissions() async {
    try {
      final results = await Future.wait([
        AirplaneModeService.checkScheduleExactAlarmPermission(),
        AirplaneModeService.hasExactAlarmPermission(),
        AirplaneModeService.hasBatteryOptimizationExemption(),
        Permission.notification.status.isGranted,
      ]);

      state = PermissionStatus(
        hasScheduleExactAlarmPermission: results[0],
        hasExactAlarmPermission: results[1],
        hasBatteryOptimizationExemption: results[2],
        hasNotificationPermission: results[3],
      );

      final allGranted = state.isAllGranted;
      AppLogger.i('All permissions granted: $allGranted');
      return allGranted;
    } catch (e) {
      AppLogger.e('Error checking permissions', e);
      return false;
    }
  }

  // Request SCHEDULE_EXACT_ALARM
  Future<void> requestScheduleExactAlarmPermission() async {
    final granted = await AirplaneModeService.requestScheduleExactAlarmPermission();
    if (granted) {
      await refreshPermissions();
    }
  }

  // Request exact alarm permission
  Future<void> requestExactAlarmPermission() async {
    await AirplaneModeService.requestExactAlarmPermission();
    await refreshPermissions();
  }

  // Request battery optimization exemption
  Future<void> requestBatteryOptimizationExemption() async {
    await AirplaneModeService.requestBatteryOptimizationExemption();
    await refreshPermissions();
  }

  // Request notification permission
  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      await refreshPermissions();
    }
  }

  // Refresh permission state
  Future<void> refreshPermissions() async {
    await checkPermissions();
  }
}

final permissionProvider = StateNotifierProvider<PermissionProvider, PermissionStatus>(
  (ref) => PermissionProvider(),
);

class PermissionStatus {
  final bool hasScheduleExactAlarmPermission;
  final bool hasExactAlarmPermission;
  final bool hasBatteryOptimizationExemption;
  final bool hasNotificationPermission;

  PermissionStatus({
    this.hasScheduleExactAlarmPermission = false,
    this.hasExactAlarmPermission = false,
    this.hasBatteryOptimizationExemption = false,
    this.hasNotificationPermission = false,
  });

  bool get isAllGranted => hasScheduleExactAlarmPermission && hasExactAlarmPermission && hasBatteryOptimizationExemption;
}
