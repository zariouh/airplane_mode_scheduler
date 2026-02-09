# Airplane Mode Scheduler - Project Summary

## Overview

A complete Flutter Android application for scheduling airplane mode with Material You design. The app allows users to create schedules that automatically toggle airplane mode at specified times.

## Key Features Implemented

### 1. Material You Design
- Dynamic color theming based on system colors
- Modern card-based UI with rounded corners
- Beautiful gradient Quick Sleep Mode card
- Smooth animations and transitions
- Light and dark theme support

### 2. Schedule Management
- Create multiple schedules with custom names
- Set enable/disable times for airplane mode
- Select specific days of the week
- Enable/disable schedules with toggle switch
- Edit and delete schedules with swipe gestures
- Quick Sleep Mode preset (10 PM - 7 AM)

### 3. Permission Handling
- **Exact Alarm Permission**: Required for precise scheduling (Android 12+)
- **Battery Optimization Exemption**: Ensures background execution
- **WRITE_SECURE_SETTINGS**: Granted via ADB for airplane mode control
- **Notification Permission**: Optional, for toggle notifications
- First-run permission wizard with step-by-step guide

### 4. Background Execution
- AlarmManager for exact time scheduling
- BroadcastReceiver for alarm triggers
- BootReceiver to reschedule after device restart
- WorkManager for backup scheduling
- Foreground service support

### 5. Native Android Integration
- Kotlin-based native code
- MethodChannel for Flutter-Android communication
- AirplaneModeManager for toggling airplane mode
- PermissionManager for permission checks
- NotificationHelper for status notifications

## Project Structure

```
airplane_mode_scheduler/
├── android/
│   └── app/src/main/kotlin/com/airplane/scheduler/
│       ├── MainActivity.kt          # Main activity with MethodChannel
│       ├── AirplaneModeManager.kt   # Airplane mode toggle logic
│       ├── PermissionManager.kt     # Permission handling
│       ├── AlarmReceiver.kt         # Alarm broadcast receiver
│       ├── BootReceiver.kt          # Boot completion receiver
│       └── NotificationHelper.kt    # Notification display
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp configuration
│   ├── models/
│   │   └── schedule_model.dart      # Schedule data model
│   ├── providers/
│   │   ├── schedule_provider.dart   # Schedule state management
│   │   └── permission_provider.dart # Permission state management
│   ├── screens/
│   │   ├── home_screen.dart         # Main screen with schedules
│   │   ├── add_schedule_screen.dart # Create/edit schedule
│   │   ├── permission_screen.dart   # First-run permissions
│   │   └── settings_screen.dart     # App settings
│   ├── services/
│   │   ├── airplane_mode_service.dart # MethodChannel service
│   │   ├── alarm_service.dart       # Alarm scheduling
│   │   ├── database_service.dart    # SQLite database
│   │   └── notification_service.dart # Flutter notifications
│   ├── widgets/
│   │   ├── quick_sleep_card.dart    # Gradient feature card
│   │   ├── schedule_card.dart       # Schedule list item
│   │   ├── empty_state.dart         # Empty list placeholder
│   │   └── bottom_nav_bar.dart      # Navigation bar
│   └── utils/
│       ├── constants.dart           # App constants
│       └── logger.dart              # Logging utility
├── codemagic.yaml                   # CI/CD configuration
├── pubspec.yaml                     # Dependencies
└── README.md                        # Documentation
```

## Technical Implementation

### Airplane Mode Toggle

Due to Android security restrictions (API 24+), apps cannot directly toggle airplane mode. The workaround:

1. Grant `WRITE_SECURE_SETTINGS` permission via ADB:
   ```bash
   adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS
   ```

2. Use `Settings.Global.putInt()` to set airplane mode state

3. Broadcast `ACTION_AIRPLANE_MODE_CHANGED` intent

### Scheduling Architecture

1. **Schedule Creation**: User creates schedule → Saved to SQLite database
2. **Alarm Registration**: `AlarmService` schedules two alarms per schedule:
   - Enable alarm (airplane mode ON)
   - Disable alarm (airplane mode OFF)
3. **Alarm Trigger**: `AlarmReceiver` receives broadcast → Toggles airplane mode
4. **Rescheduling**: After trigger, alarm is rescheduled for next occurrence

### State Management

- **Riverpod** for reactive state management
- **ScheduleProvider**: Manages schedule list and CRUD operations
- **PermissionProvider**: Tracks permission states

### Database

- **SQLite** via sqflite package
- Stores schedule data with JSON-encoded time and days
- Supports CRUD operations

## Dependencies

### Flutter Packages
- `flutter_riverpod`: State management
- `android_alarm_manager_plus`: Alarm scheduling
- `workmanager`: Background tasks
- `sqflite`: Local database
- `shared_preferences`: Simple storage
- `permission_handler`: Runtime permissions
- `flutter_local_notifications`: Local notifications
- `google_fonts`: Typography
- `flutter_slidable`: Swipe actions
- `lucide_icons`: Icon pack
- `intl`: Internationalization
- `uuid`: Unique ID generation

### Android Native
- Kotlin 1.9.21
- Android SDK 34
- Minimum SDK 21 (Android 5.0)
- AlarmManager for scheduling
- BroadcastReceiver for events

## Building & Deployment

### Local Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### Codemagic CI/CD

1. Connect GitHub repository to Codemagic
2. Configure code signing (keystore)
3. Push to main branch triggers build
4. Download artifacts from Codemagic dashboard

## Permissions Required

| Permission | Source | Purpose |
|------------|--------|---------|
| `WRITE_SECURE_SETTINGS` | ADB | Toggle airplane mode |
| `SCHEDULE_EXACT_ALARM` | Runtime | Exact time scheduling |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Runtime | Background execution |
| `RECEIVE_BOOT_COMPLETED` | Manifest | Reschedule on boot |
| `WAKE_LOCK` | Manifest | Keep awake during alarm |
| `POST_NOTIFICATIONS` | Runtime | Show notifications |

## Known Limitations

1. **ADB Setup Required**: Users must grant WRITE_SECURE_SETTINGS via ADB
2. **No iOS Support**: iOS doesn't allow airplane mode control
3. **Android 7+ Only**: Earlier versions had different APIs
4. **Some OEM Restrictions**: Samsung, Xiaomi may have additional battery restrictions

## Future Enhancements

- [ ] Widget support for quick toggle
- [ ] Execution history/log
- [ ] Import/export schedules
- [ ] Dark mode schedule (disable at sunrise)
- [ ] Smart suggestions based on usage
- [ ] Backup to cloud

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] Create schedule
- [ ] Edit schedule
- [ ] Delete schedule
- [ ] Toggle schedule on/off
- [ ] Verify alarm triggers
- [ ] Check airplane mode toggle
- [ ] Test after device reboot
- [ ] Verify battery optimization handling

## Security Considerations

1. ADB permission is one-time setup
2. No network permissions required
3. Data stored locally only
4. No analytics or tracking

## License

MIT License - See LICENSE file

---

**Created**: 2025
**Flutter Version**: 3.16+
**Dart Version**: 3.0+
