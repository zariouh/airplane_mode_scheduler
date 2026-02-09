import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class AirplaneModeService {
  static const MethodChannel _channel = MethodChannel(
    'com.airplane.scheduler/airplane_mode',
  );

  // Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    try {
      final results = await Future.wait([
        hasExactAlarmPermission(),
        hasBatteryOptimizationExemption(),
        hasWriteSecureSettingsPermission(),
      ]);
      
      // All permissions must be granted
      return results.every((result) => result);
    } catch (e) {
      AppLogger.e('Error checking all permissions', e);
      return false;
    }
  }

  // Check exact alarm permission (Android 12+)
  static Future<bool> hasExactAlarmPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasExactAlarmPermission');
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error checking exact alarm permission', e);
      return false;
    }
  }

  // Request exact alarm permission
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

  // Check WRITE_SECURE_SETTINGS permission
  static Future<bool> hasWriteSecureSettingsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasWriteSecureSettingsPermission');
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error checking WRITE_SECURE_SETTINGS permission', e);
      return false;
    }
  }

  // Open instructions for granting WRITE_SECURE_SETTINGS via ADB
  static Future<void> openWriteSecureSettingsInstructions() async {
    try {
      await _channel.invokeMethod('openWriteSecureSettingsInstructions');
    } catch (e) {
      AppLogger.e('Error opening write secure settings instructions', e);
      throw Exception('Failed to open instructions: $e');
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
