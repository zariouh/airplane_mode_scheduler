import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'services/notification_service.dart';
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
  
  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();
  
  // Initialize WorkManager
  // REMOVED: isInDebugMode parameter (deprecated in workmanager 0.9.0+)
  await Workmanager().initialize(callbackDispatcher);
  
  // Initialize Notification Service
  await NotificationService().init();
  
  AppLogger.i('App initialized');
  
  runApp(
    const ProviderScope(
      child: AirplaneModeSchedulerApp(),
    ),
  );
}
