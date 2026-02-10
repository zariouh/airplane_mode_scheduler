import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/alarm_service.dart';
import 'utils/logger.dart';

// Background callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.i('WorkManager task executed: $task');
    return Future.value(true);
  });
}

// Background alarm callback
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  AppLogger.i('Alarm fired: $id');
  // Handle alarm in native code
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Android Alarm Manager
    await AndroidAlarmManager.initialize();
    AppLogger.i('AndroidAlarmManager initialized');
    
    // Initialize WorkManager
    await Workmanager().initialize(callbackDispatcher);
    AppLogger.i('WorkManager initialized');
    
    // Initialize Notification Service
    await NotificationService().init();
    AppLogger.i('NotificationService initialized');
    
    // ✅ NEW: Reschedule all enabled schedules on app startup
    // This ensures schedules work after device reboot
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

/// Reschedule all enabled schedules
/// This is called on app startup to ensure schedules persist after reboot
Future<void> _rescheduleAllEnabledSchedules() async {
  try {
    AppLogger.i('Rescheduling all enabled schedules...');
    
    final db = DatabaseService();
    final alarmService = AlarmService();
    
    // Get all schedules from database
    final schedules = await db.getAllSchedules();
    
    // Filter and reschedule only enabled schedules
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
    // Don't throw - app should still start even if rescheduling fails
  }
}
