import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'airplane_mode_scheduler';
  static const String _channelName = 'Airplane Mode Scheduler';
  static const String _channelDescription = 
      'Notifications for airplane mode schedule events';

  // Initialize notification service
  Future<void> init() async {
    try {
      AppLogger.i('Initializing notification service');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // ✅ FIXED: v18.x uses all named parameters
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      AppLogger.i('Notification service initialized');
    } catch (e) {
      AppLogger.e('Error initializing notification service', e);
    }
  }

  // Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    AppLogger.i('Notification response: ${response.payload}');
    // Handle notification tap
  }

  // Show airplane mode toggle notification
  Future<void> showAirplaneModeNotification({
    required bool enabled,
    String? scheduleName,
  }) async {
    try {
      final title = enabled 
          ? 'Airplane Mode Enabled' 
          : 'Airplane Mode Disabled';
      final body = scheduleName != null
          ? 'Schedule "$scheduleName" ${enabled ? 'enabled' : 'disabled'} airplane mode'
          : 'Airplane mode has been ${enabled ? 'enabled' : 'disabled'}';

      final AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: enabled ? Colors.green : Colors.blue,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // All parameters as named
      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: 'airplane_mode_${enabled ? 'on' : 'off'}',
      );

      AppLogger.i('Notification shown: $title');
    } catch (e) {
      AppLogger.e('Error showing notification', e);
    }
  }

  // Show schedule reminder notification
  Future<void> showScheduleReminder({
    required String scheduleName,
    required DateTime scheduledTime,
    required bool willEnable,
  }) async {
    try {
      final title = willEnable 
          ? 'Airplane Mode Will Be Enabled' 
          : 'Airplane Mode Will Be Disabled';
      final body = 
          '"$scheduleName" will ${willEnable ? 'enable' : 'disable'} airplane mode at '
          '${_formatTime(scheduledTime)}';

      final AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: 'schedule_reminder',
      );
    } catch (e) {
      AppLogger.e('Error showing schedule reminder', e);
    }
  }

  // Show permission required notification
  Future<void> showPermissionRequiredNotification() async {
    try {
      const AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0,
        'Permissions Required',
        'Please grant required permissions for Airplane Mode Scheduler to work properly',
        details,
        payload: 'permission_required',
      );
    } catch (e) {
      AppLogger.e('Error showing permission notification', e);
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      AppLogger.i('All notifications cancelled');
    } catch (e) {
      AppLogger.e('Error cancelling notifications', e);
    }
  }

  // Format time helper
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
