import 'package:flutter/services.dart';
import '../models/schedule_model.dart';
import '../utils/logger.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel(
    'com.airplane.scheduler/airplane_mode',
  );

  Future<void> scheduleAirplaneModeToggle(Schedule schedule) async {
    try {
      AppLogger.i('Scheduling airplane mode toggles for: ${schedule.name}');
      await cancelScheduleAlarms(schedule.id);

      // Schedule enable alarm
      await _channel.invokeMethod('scheduleAlarm', {
        'alarmId': _generateAlarmId(schedule.id, true),
        'hour': schedule.enableTime.hour,
        'minute': schedule.enableTime.minute,
        'daysOfWeek': schedule.daysOfWeek,
        'enable': true,
        'scheduleId': schedule.id,
        'scheduleName': schedule.name,
      });

      // Schedule disable alarm
      await _channel.invokeMethod('scheduleAlarm', {
        'alarmId': _generateAlarmId(schedule.id, false),
        'hour': schedule.disableTime.hour,
        'minute': schedule.disableTime.minute,
        'daysOfWeek': schedule.daysOfWeek,
        'enable': false,
        'scheduleId': schedule.id,
        'scheduleName': schedule.name,
      });

      AppLogger.i('Successfully scheduled alarms for: ${schedule.name}');
    } catch (e) {
      AppLogger.e('Error scheduling airplane mode toggles', e);
    }
  }

  Future<void> cancelScheduleAlarms(String scheduleId) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {
        'alarmId': _generateAlarmId(scheduleId, true),
      });
      await _channel.invokeMethod('cancelAlarm', {
        'alarmId': _generateAlarmId(scheduleId, false),
      });
      AppLogger.i('Cancelled alarms for schedule: $scheduleId');
    } catch (e) {
      AppLogger.e('Error cancelling alarms', e);
    }
  }

  int _generateAlarmId(String scheduleId, bool isEnable) {
    final combined = '$scheduleId-${isEnable ? 'enable' : 'disable'}';
    return combined.hashCode.abs() % 1000000;
  }
}
