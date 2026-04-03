import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/schedule_model.dart';
import '../utils/logger.dart';

// Background callback - runs in separate isolate
// Does NOT use MethodChannel (won't work in background isolate)
// The actual airplane mode toggle is handled by AlarmReceiver.kt on the native side
@pragma('vm:entry-point')
void airplaneModeCallback(int id, Map<String, dynamic>? params) async {
  try {
    final enable = params?['enable'] as bool? ?? false;
    final scheduleName = params?['scheduleName'] as String? ?? 'Unknown';

    AppLogger.i('Alarm callback triggered: enable=$enable, schedule=$scheduleName');

    // Reschedule for next occurrence
    if (params != null) {
      final scheduleId = params['scheduleId'] as String?;
      final daysOfWeekDynamic = params['daysOfWeek'] as List<dynamic>?;
      final hour = params['hour'] as int?;
      final minute = params['minute'] as int?;
      final alarmId = params['alarmId'] as int?;

      if (scheduleId != null && daysOfWeekDynamic != null &&
          hour != null && minute != null && alarmId != null) {
        final daysOfWeek = daysOfWeekDynamic.map((e) => e as bool).toList();

        final now = DateTime.now();
        var nextTime = DateTime(now.year, now.month, now.day, hour, minute)
            .add(const Duration(days: 1));

        while (!daysOfWeek[nextTime.weekday - 1]) {
          nextTime = nextTime.add(const Duration(days: 1));
        }

        final rescheduled = await AndroidAlarmManager.oneShotAt(
          nextTime,
          alarmId,
          airplaneModeCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: params,
        );

        if (rescheduled) {
          AppLogger.i('Rescheduled alarm $alarmId for $nextTime');
        }
      }
    }
  } catch (e, stackTrace) {
    AppLogger.e('Error in airplane mode callback', e);
    print('Stack trace: $stackTrace');
  }
}

class AlarmService {
  Future<void> scheduleAirplaneModeToggle(Schedule schedule) async {
    try {
      AppLogger.i('Scheduling airplane mode toggles for: ${schedule.name}');
      await cancelScheduleAlarms(schedule.id);

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
    }
  }

  Future<void> cancelScheduleAlarms(String scheduleId) async {
    try {
      await AndroidAlarmManager.cancel(_generateAlarmId(scheduleId, true));
      await AndroidAlarmManager.cancel(_generateAlarmId(scheduleId, false));
      AppLogger.i('Cancelled alarms for schedule: $scheduleId');
    } catch (e) {
      AppLogger.e('Error cancelling alarms', e);
    }
  }

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
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      while (!daysOfWeek[scheduledTime.weekday - 1]) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final success = await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        airplaneModeCallback,
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
      }
    } catch (e) {
      AppLogger.e('Error scheduling daily alarm', e);
    }
  }

  int _generateAlarmId(String scheduleId, bool isEnable) {
    final combined = '$scheduleId-${isEnable ? 'enable' : 'disable'}';
    return combined.hashCode.abs() % 1000000;
  }
}
