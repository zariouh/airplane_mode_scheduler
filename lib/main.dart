import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Notification Service
    await NotificationService().init();
    AppLogger.i('NotificationService initialized');
    
    // Reschedule all enabled schedules on app startup
    // This ensures schedules survive after device reboot
    await _rescheduleAllEnabledSchedules();
    
    AppLogger.i('App initialized successfully');
  } catch (e) {
    AppLogger.e('Error during app initialization', e);
  }
  
  runApp(
    const ProviderScope(
      child: AirplaneModeSchedulerApp(),
    ),
  );
}

Future<void> _rescheduleAllEnabledSchedules() async {
  try {
    AppLogger.i('Rescheduling all enabled schedules...');
    
    final db = DatabaseService();
    final alarmService = AlarmService();
    final schedules = await db.getAllSchedules();
    final enabledSchedules = schedules.where((s) => s.isEnabled).toList();
    
    if (enabledSchedules.isEmpty) {
      AppLogger.i('No enabled schedules to reschedule');
      return;
    }
    
    int successCount = 0;
    int failCount = 0;
    
    for (final schedule in enabledSchedules) {
      try {
        await alarmService.scheduleAirplaneModeToggle(schedule);
        successCount++;
        AppLogger.i('Rescheduled: ${schedule.name}');
      } catch (e) {
        failCount++;
        AppLogger.e('Failed to reschedule: ${schedule.name}', e);
      }
    }
    
    AppLogger.i(
      'Rescheduling complete: $successCount succeeded, $failCount failed '
      '(${enabledSchedules.length} total)'
    );
  } catch (e) {
    AppLogger.e('Error rescheduling schedules on boot', e);
  }
}
