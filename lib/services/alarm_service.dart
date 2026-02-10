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
        scheduleId: schedule.id,
        scheduleName: schedule.name,
      );
      
      // Schedule disable alarm (airplane mode OFF)
      final disableAlarmId = _generateAlarmId(schedule.id, false);
      await _scheduleDailyAlarm(
        id: disableAlarmId,
        hour: schedule.disableTime.hour,
        minute: schedule.disableTime.minute,
        daysOfWeek: schedule.daysOfWeek,
        enableAirplaneMode: false,
        scheduleId: schedule.id,
        scheduleName: schedule.name,
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
    required String scheduleId,
    required String scheduleName,
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

      // ✅ FIXED: Pass all necessary data for rescheduling
      final success = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        _airplaneModeCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'enable': enableAirplaneMode,
          'scheduleId': scheduleId,
          'scheduleName': scheduleName,
          'daysOfWeek': daysOfWeek,
          'hour': hour,
          'minute': minute,
          'alarmId': id,
        },
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
    // ✅ IMPROVED: Better ID generation to prevent collisions
    final combined = '$scheduleId-${isEnable ? 'enable' : 'disable'}';
    return combined.hashCode.abs() % 1000000;
  }

  // ✅ FIXED: Background callback with self-rescheduling
  @pragma('vm:entry-point')
  static void _airplaneModeCallback(int id, Map<String, dynamic>? params) async {
    try {
      final enable = params?['enable'] as bool? ?? false;
      final scheduleName = params?['scheduleName'] as String? ?? 'Unknown';
      AppLogger.i('Alarm callback triggered: id=$id, enable=$enable, schedule=$scheduleName');
      
      // Try to toggle airplane mode
      final success = await AirplaneModeService.toggleAirplaneMode(enable);
      
      if (success) {
        AppLogger.i('Successfully toggled airplane mode: $enable');
        
        // Show notification (optional)
        try {
          // You can add notification here if needed
        } catch (e) {
          // ✅ FIXED: Use AppLogger.e() instead of AppLogger.w() with error parameter
          AppLogger.e('Failed to show notification', e);
        }
      } else {
        AppLogger.w('Failed to toggle airplane mode automatically');
      }
      
      // ✅ CRITICAL FIX: Reschedule for next occurrence
      if (params != null) {
        final scheduleId = params['scheduleId'] as String?;
        final daysOfWeekDynamic = params['daysOfWeek'] as List<dynamic>?;
        final hour = params['hour'] as int?;
        final minute = params['minute'] as int?;
        final alarmId = params['alarmId'] as int?;
        
        if (scheduleId != null && 
            daysOfWeekDynamic != null && 
            hour != null && 
            minute != null &&
            alarmId != null) {
          
          // Convert dynamic list to List<bool>
          final daysOfWeek = daysOfWeekDynamic.map((e) => e as bool).toList();
          
          // Calculate next occurrence
          final now = DateTime.now();
          var nextTime = DateTime(now.year, now.month, now.day, hour, minute);
          
          // Move to next day
          nextTime = nextTime.add(const Duration(days: 1));
          
          // Find next active day
          while (!daysOfWeek[nextTime.weekday - 1]) {
            nextTime = nextTime.add(const Duration(days: 1));
          }
          
          // ✅ FIXED: Handle null params properly
          // Reschedule the alarm with the same params
          final rescheduled = await AndroidAlarmManager.oneShotAt(
            nextTime,
            alarmId,
            _airplaneModeCallback,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
            params: {
              'enable': enable,
              'scheduleId': scheduleId,
              'scheduleName': scheduleName,
              'daysOfWeek': daysOfWeek,
              'hour': hour,
              'minute': minute,
              'alarmId': alarmId,
            },
          );
          
          if (rescheduled) {
            AppLogger.i('Rescheduled alarm $alarmId for $nextTime');
          } else {
            AppLogger.w('Failed to reschedule alarm $alarmId');
          }
        } else {
          AppLogger.w('Missing required parameters for rescheduling');
        }
      } else {
        AppLogger.w('Params is null, cannot reschedule');
      }
      
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
        params: {
          'enable': enableAirplaneMode,
          'scheduleName': 'Test Alarm',
          // Note: test alarm won't reschedule (missing required params)
        },
      );

      AppLogger.i('Test alarm scheduled: success=$success, id=$id, time=$scheduledTime');
    } catch (e) {
      AppLogger.e('Error scheduling test alarm', e);
      throw Exception('Failed to schedule test alarm: $e');
    }
  }
}
