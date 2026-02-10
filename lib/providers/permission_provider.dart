import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/airplane_mode_service.dart';
import '../utils/logger.dart';

// Permission status model
class PermissionStatus {
  final bool hasScheduleExactAlarmPermission; // ADDED
  final bool hasExactAlarmPermission;
  final bool hasBatteryOptimizationExemption;
  final bool hasWriteSecureSettings;
  final bool hasNotificationPermission;
  final bool isAllGranted;

  const PermissionStatus({
    this.hasScheduleExactAlarmPermission = false, // ADDED
    this.hasExactAlarmPermission = false,
    this.hasBatteryOptimizationExemption = false,
    this.hasWriteSecureSettings = false,
    this.hasNotificationPermission = false,
    this.isAllGranted = false,
  });

  PermissionStatus copyWith({
    bool? hasScheduleExactAlarmPermission, // ADDED
    bool? hasExactAlarmPermission,
    bool? hasBatteryOptimizationExemption,
    bool? hasWriteSecureSettings,
    bool? hasNotificationPermission,
    bool? isAllGranted,
  }) {
    return PermissionStatus(
      hasScheduleExactAlarmPermission: hasScheduleExactAlarmPermission ?? this.hasScheduleExactAlarmPermission, // ADDED
      hasExactAlarmPermission: hasExactAlarmPermission ?? this.hasExactAlarmPermission,
      hasBatteryOptimizationExemption: hasBatteryOptimizationExemption ?? this.hasBatteryOptimizationExemption,
      hasWriteSecureSettings: hasWriteSecureSettings ?? this.hasWriteSecureSettings,
      hasNotificationPermission: hasNotificationPermission ?? this.hasNotificationPermission,
      isAllGranted: isAllGranted ?? this.isAllGranted,
    );
  }
}

// Permission provider
final permissionProvider = StateNotifierProvider<PermissionNotifier, PermissionStatus>((ref) {
  return PermissionNotifier();
});

class PermissionNotifier extends StateNotifier<PermissionStatus> {
  PermissionNotifier() : super(const PermissionStatus()) {
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    try {
      AppLogger.i('Checking all permissions');
      
      // ADDED: Check SCHEDULE_EXACT_ALARM permission
      final hasScheduleExactAlarm = await AirplaneModeService.checkScheduleExactAlarmPermission();
      final hasExactAlarm = await AirplaneModeService.hasExactAlarmPermission();
      final hasBatteryOpt = await AirplaneModeService.hasBatteryOptimizationExemption();
      final hasWriteSecure = await AirplaneModeService.hasWriteSecureSettingsPermission();
      final hasNotification = await _checkNotificationPermission();

      // UPDATED: Include schedule exact alarm in all granted check
      final isAllGranted = hasScheduleExactAlarm && hasExactAlarm && hasBatteryOpt && hasWriteSecure;

      state = PermissionStatus(
        hasScheduleExactAlarmPermission: hasScheduleExactAlarm, // ADDED
        hasExactAlarmPermission: hasExactAlarm,
        hasBatteryOptimizationExemption: hasBatteryOpt,
        hasWriteSecureSettings: hasWriteSecure,
        hasNotificationPermission: hasNotification,
        isAllGranted: isAllGranted,
      );

      AppLogger.i('Permission status: scheduleExactAlarm=$hasScheduleExactAlarm, exactAlarm=$hasExactAlarm, batteryOpt=$hasBatteryOpt, writeSecure=$hasWriteSecure, notification=$hasNotification');
    } catch (e) {
      AppLogger.e('Error checking permissions', e);
    }
  }

  // ADDED: refreshPermissions method (alias for checkPermissions)
  Future<void> refreshPermissions() async {
    await checkPermissions();
  }

  Future<bool> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      final isGranted = status.isGranted;
      
      state = state.copyWith(
        hasNotificationPermission: isGranted,
        isAllGranted: isGranted && 
                      state.hasScheduleExactAlarmPermission && // UPDATED
                      state.hasExactAlarmPermission && 
                      state.hasBatteryOptimizationExemption && 
                      state.hasWriteSecureSettings,
      );
      
      return isGranted;
    } catch (e) {
      AppLogger.e('Error requesting notification permission', e);
      return false;
    }
  }

  // ADDED: Request schedule exact alarm permission
  Future<bool> requestScheduleExactAlarmPermission() async {
    try {
      final granted = await AirplaneModeService.requestScheduleExactAlarmPermission();
      
      // Recheck after request
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
      
      return granted;
    } catch (e) {
      AppLogger.e('Error requesting schedule exact alarm permission', e);
      return false;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    try {
      await AirplaneModeService.requestExactAlarmPermission();
      // Recheck after request
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
    } catch (e) {
      AppLogger.e('Error requesting exact alarm permission', e);
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    try {
      await AirplaneModeService.requestBatteryOptimizationExemption();
      // Recheck after request
      await Future.delayed(const Duration(seconds: 1));
      await checkPermissions();
    } catch (e) {
      AppLogger.e('Error requesting battery optimization exemption', e);
    }
  }

  Future<void> openWriteSecureSettingsInstructions() async {
    try {
      await AirplaneModeService.openWriteSecureSettingsInstructions();
    } catch (e) {
      AppLogger.e('Error opening write secure settings instructions', e);
    }
  }

  Future<void> verifyWriteSecureSettingsPermission() async {
    try {
      final hasPermission = await AirplaneModeService.hasWriteSecureSettingsPermission();
      state = state.copyWith(
        hasWriteSecureSettings: hasPermission,
        isAllGranted: hasPermission && 
                      state.hasScheduleExactAlarmPermission && // UPDATED
                      state.hasExactAlarmPermission && 
                      state.hasBatteryOptimizationExemption && 
                      state.hasNotificationPermission,
      );
    } catch (e) {
      AppLogger.e('Error verifying write secure settings permission', e);
    }
  }
}
