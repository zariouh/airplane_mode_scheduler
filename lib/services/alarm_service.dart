import 'dart:math';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/schedule_model.dart';
import 'airplane_mode_service.dart';
import '../utils/logger.dart';

class AlarmService {
  // Schedule airplane mode toggle for a schedule
  Future<void> scheduleAirplaneModeToggle(Schedule schedule) async {
    try {
      AppLogger.i('Scheduling airplane mode toggles for: ${schedule.name}');
      
      // Cancel existing alarms first
      await cancelScheduleAlarms(schedule.id);
      
      // Schedule enable alarm (airplane mode ON)
      final enableAlarmId = _generateAlarmId(schedule.id, true);
      await _scheduleDailyAlarm(
        id: enableAlarmId,
        hour: schedule.enableTime.hour,
        minute: schedule.enableTime.minute,
        daysOfWeek: schedule.daysOfWeek,
        enableAirplaneMode: true,
      );
      
      // Schedule disable alarm (airplane mode OFF)
      final disableAlarmId = _generateAlarmId(schedule.id, false);
      await _scheduleDailyAlarm(
        id: disableAlarmId,
        hour: schedule.disableTime.hour,
        minute: schedule.disableTime.minute,
        daysOfWeek: schedule.daysOfWeek,
        enableAirplaneMode: false,
      );
      
      AppLogger.i('Successfully scheduled alarms for: ${schedule.name}');
    } catch (e) {
      AppLogger.e('Error scheduling airplane mode toggles', e);
      throw Exception('Failed to schedule alarms: $e');
    }
  }

  // Cancel all alarms for a schedule
  Future<void> cancelScheduleAlarms(String scheduleId) async {
    try {
      final enableAlarmId = _generateAlarmId(scheduleId, true);
      final disableAlarmId = _generateAlarmId(scheduleId, false);
      
      await AndroidAlarmManager.cancel(enableAlarmId);
      await AndroidAlarmManager.cancel(disableAlarmId);
      
      AppLogger.i('Cancelled alarms for schedule: $scheduleId');
    } catch (e) {
      AppLogger.e('Error cancelling alarms', e);
    }
  }

  // Schedule a daily alarm
  Future<void> _scheduleDailyAlarm({
    required int id,
    required int hour,
    required int minute,
    required List<bool> daysOfWeek,
    required bool enableAirplaneMode,
  }) async {
    try {
      final now = DateTime.now();
      var scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Find the next active day
      while (!daysOfWeek[scheduledTime.weekday - 1]) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final success = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        _airplaneModeCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {'enable': enableAirplaneMode},
      );

      if (success) {
        AppLogger.i('Scheduled alarm $id at $scheduledTime, enable: $enableAirplaneMode');
      } else {
        AppLogger.w('Failed to schedule alarm $id');
      }
    } catch (e) {
      AppLogger.e('Error scheduling daily alarm', e);
      throw Exception('Failed to schedule alarm: $e');
    }
  }

  // Generate unique alarm ID from schedule ID and type
  int _generateAlarmId(String scheduleId, bool isEnable) {
    // Use hashCode to generate a consistent integer ID
    final baseId = scheduleId.hashCode.abs();
    return isEnable ? baseId : baseId + 1;
  }

  // Background callback for airplane mode toggle
  @pragma('vm:entry-point')
  static void _airplaneModeCallback(int id, Map<String, dynamic>? params) async {
    try {
      final enable = params?['enable'] as bool? ?? false;
      AppLogger.i('Alarm callback triggered: id=$id, enable=$enable');
      
      // Try to toggle airplane mode
      final success = await AirplaneModeService.toggleAirplaneMode(enable);
      
      if (success) {
        AppLogger.i('Successfully toggled airplane mode: $enable');
      } else {
        AppLogger.w('Failed to toggle airplane mode automatically');
        // Could show notification here to inform user
      }
      
      // Reschedule for next occurrence
      // This is handled by rescheduleOnReboot: true in oneShotAt
    } catch (e) {
      AppLogger.e('Error in airplane mode callback', e);
    }
  }

  // Test alarm (for debugging)
  Future<void> scheduleTestAlarm({
    required int delaySeconds,
    required bool enableAirplaneMode,
  }) async {
    try {
      final id = Random().nextInt(100000);
      final scheduledTime = DateTime.now().add(Duration(seconds: delaySeconds));
      
      final success = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        _airplaneModeCallback,
        exact: true,
        wakeup: true,
        params: {'enable': enableAirplaneMode},
      );

      AppLogger.i('Test alarm scheduled: success=$success, id=$id, time=$scheduledTime');
    } catch (e) {
      AppLogger.e('Error scheduling test alarm', e);
      throw Exception('Failed to schedule test alarm: $e');
    }
  }
}
