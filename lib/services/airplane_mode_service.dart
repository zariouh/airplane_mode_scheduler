import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart'; // ADD THIS IMPORT
import '../utils/logger.dart';

class AirplaneModeService {
  static const MethodChannel _channel = MethodChannel(
    'com.airplane.scheduler/airplane_mode',
  );

  // Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    try {
      // ADDED: Check SCHEDULE_EXACT_ALARM permission (critical for Android 14+)
      final scheduleExactAlarmStatus = await Permission.scheduleExactAlarm.status;
      AppLogger.i('SCHEDULE_EXACT_ALARM status: $scheduleExactAlarmStatus');
      
      final results = await Future.wait([
        hasExactAlarmPermission(),
        hasBatteryOptimizationExemption(),
        // Removed: hasWriteSecureSettingsPermission() — root handles airplane toggle now
      ]);
      
      // All permissions must be granted
      final allGranted = results.every((result) => result) && scheduleExactAlarmStatus.isGranted;
      
      if (!allGranted) {
        AppLogger.w('Not all permissions granted. '
            'ScheduleExactAlarm: ${scheduleExactAlarmStatus.isGranted}, '
            'ExactAlarm: ${results[0]}, '
            'Battery: ${results[1]}');
      }
      
      return allGranted;
    } catch (e) {
      AppLogger.e('Error checking all permissions', e);
      return false;
    }
  }

  // ADDED: Check SCHEDULE_EXACT_ALARM permission using permission_handler
  static Future<bool> checkScheduleExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      AppLogger.i('Schedule exact alarm permission status: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.e('Error checking schedule exact alarm permission', e);
      return false;
    }
  }

  // ADDED: Request SCHEDULE_EXACT_ALARM permission (opens system settings)
  static Future<bool> requestScheduleExactAlarmPermission() async {
    try {
      // On Android 14+, this opens system settings dialog
      final status = await Permission.scheduleExactAlarm.request();
      AppLogger.i('Schedule exact alarm permission request result: $status');
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Open settings if permanently denied
        await openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.e('Error requesting schedule exact alarm permission', e);
      return false;
    }
  }

  // Check exact alarm permission (legacy method channel)
  static Future<bool> hasExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasExactAlarmPermission');
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error checking exact alarm permission', e);
      return false;
    }
  }

  // Request exact alarm permission (legacy)
  static Future<void> requestExactAlarmPermission() async {
    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      AppLogger.e('Error requesting exact alarm permission', e);
      throw Exception('Failed to request exact alarm permission: $e');
    }
  }

  // Check battery optimization exemption
  static Future<bool> hasBatteryOptimizationExemption() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasBatteryOptimizationExemption');
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error checking battery optimization exemption', e);
      return false;
    }
  }

  // Request battery optimization exemption
  static Future<void> requestBatteryOptimizationExemption() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimizationExemption');
    } catch (e) {
      AppLogger.e('Error requesting battery optimization exemption', e);
      throw Exception('Failed to request battery optimization exemption: $e');
    }
  }

  // Toggle airplane mode on/off
  static Future<bool> toggleAirplaneMode(bool enable) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'toggleAirplaneMode',
        {'enable': enable},
      );
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error toggling airplane mode', e);
      return false;
    }
  }

  // Check current airplane mode status
  static Future<bool> isAirplaneModeOn() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAirplaneModeOn');
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error checking airplane mode status', e);
      return false;
    }
  }

  // Open airplane mode settings
  static Future<void> openAirplaneModeSettings() async {
    try {
      await _channel.invokeMethod('openAirplaneModeSettings');
    } catch (e) {
      AppLogger.e('Error opening airplane mode settings', e);
      throw Exception('Failed to open settings: $e');
    }
  }
}
