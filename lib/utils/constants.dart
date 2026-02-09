import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = 'Airplane Mode Scheduler';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyPermissionsGranted = 'permissions_granted';
  static const String keySchedules = 'schedules';
  
  // Permission request codes
  static const int requestExactAlarm = 1001;
  static const int requestBatteryOptimization = 1002;
  static const int requestNotification = 1003;
  
  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Default schedule times
  static const TimeOfDay defaultBedtime = TimeOfDay(hour: 22, minute: 0);
  static const TimeOfDay defaultWakeTime = TimeOfDay(hour: 7, minute: 0);
  
  // Days of week
  static const List<String> dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  
  // Colors
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFF958DA5);
  static const Color tertiaryColor = Color(0xFFB58392);
  
  // Gradient colors for Quick Sleep Card
  static const List<Color> sleepGradientColors = [
    Color(0xFF6750A4),
    Color(0xFF958DA5),
  ];
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  
  // Border radius
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;
  
  // Max content width
  static const double maxContentWidth = 600.0;
}
