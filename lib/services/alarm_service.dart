import 'dart:math';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/schedule_model.dart';
import 'airplane_mode_service.dart';
import 'notification_service.dart';
import '../utils/logger.dart';

// ✅ CRITICAL FIX: Callback MUST be a top-level function, not a class method!
@pragma('vm:entry-point')
void airplaneModeCallback(int id, Map<String, dynamic>? params) async {
  try {
    final enable = params?['enable'] as bool? ?? false;
    final scheduleName = params?['scheduleName'] as String? ?? 'Unknown';
    AppLogger.i('🔔 Alarm callback triggered: id=$id, enable=$enable, schedule=$scheduleName');
    
    // Try to toggle airplane mode
    final success = await AirplaneModeService.toggleAirplaneMode(enable);
    
    if (success) {
      AppLogger.i('✅ Successfully toggled airplane mode: $enable');
      
      // Show notification
      try {
        await NotificationService().showAirplaneModeNotification(
          enabled: enable,
          scheduleName: scheduleName,
        );
      } catch (e) {
        AppLogger.e('Failed to show notification', e);
      }
    } else {
      AppLogger.w('❌ Failed to toggle airplane mode automatically');
    }
    
    // ✅ CRITICAL: Reschedule for next occurrence
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
        
        // Reschedule the alarm
        final rescheduled = await AndroidAlarmManager.oneShotAt(
          nextTime,
          alarmId,
          airplaneModeCallback,  // Reference top-level function
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: params,  // Pass same params
        );
        
        if (rescheduled) {
          AppLogger.i('📅 Rescheduled alarm $alarmId for $nextTime');
        } else {
          AppLogger.w('⚠️ Failed to reschedule alarm $alarmId');
        }
      } else {
        AppLogger.w('⚠️ Missing required parameters for rescheduling');
      }
    } else {
      AppLogger.w('⚠️ Params is null, cannot reschedule');
    }
    
  } catch (e, stackTrace) {
    AppLogger.e('💥 Error in airplane mode callback', e);
    print('Stack trace: $stackTrace');
  }
}

class AlarmService {
  // Schedule airplane mode toggle for a schedule
  Future<void> scheduleAirplaneModeToggle(Schedule schedule) async {
    try {
      AppLogger.i('📋 Scheduling airplane mode toggles for: ${schedule.name}');
      
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
      
      AppLogger.i('✅ Successfully scheduled alarms for: ${schedule.name}');
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
      
      AppLogger.i('🗑️ Cancelled alarms for schedule: $scheduleId');
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

      // ✅ FIXED: Use top-level callback function
      final success = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        airplaneModeCallback,  // ✅ Reference top-level function
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
        AppLogger.i('⏰ Scheduled alarm $id at $scheduledTime, enable: $enableAirplaneMode');
      } else {
        AppLogger.w('❌ Failed to schedule alarm $id');
      }
    } catch (e) {
      AppLogger.e('Error scheduling daily alarm', e);
      throw Exception('Failed to schedule alarm: $e');
    }
  }

  // Generate unique alarm ID from schedule ID and type
  int _generateAlarmId(String scheduleId, bool isEnable) {
    final combined = '$scheduleId-${isEnable ? 'enable' : 'disable'}';
    return combined.hashCode.abs() % 1000000;
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
        airplaneModeCallback,  // ✅ Reference top-level function
        exact: true,
        wakeup: true,
        params: {
          'enable': enableAirplaneMode,
          'scheduleName': 'Test Alarm',
          'scheduleId': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'daysOfWeek': List.generate(7, (_) => true),
          'hour': scheduledTime.hour,
          'minute': scheduledTime.minute,
          'alarmId': id,
        },
      );

      AppLogger.i('🧪 Test alarm scheduled: success=$success, id=$id, time=$scheduledTime');
    } catch (e) {
      AppLogger.e('Error scheduling test alarm', e);
      throw Exception('Failed to schedule test alarm: $e');
    }
  }
}
