# Airplane Mode Scheduler

A beautiful Material You designed Android app that allows you to schedule airplane mode automatically. Perfect for sleep schedules, work hours, or any time you want your device to automatically disconnect from all networks.

![Material You Design](https://img.shields.io/badge/Material%20You-3.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue)
![Android](https://img.shields.io/badge/Android-5.0+-green)

## Features

- **Quick Sleep Mode**: One-tap setup for bedtime airplane mode
- **Custom Schedules**: Create multiple schedules with different times and days
- **Material You Design**: Beautiful, modern UI with dynamic theming
- **Background Execution**: Works even when the app is closed
- **Battery Optimization**: Handles all necessary permissions for reliable operation
- **Notifications**: Get notified when airplane mode is toggled

## Screenshots

*Coming soon*

## Prerequisites

Before using this app, you need to grant a special permission via ADB (Android Debug Bridge). This is a one-time setup required for the app to control airplane mode automatically.

### Why is ADB required?

Android disabled programmatic airplane mode control starting from Android 7.0 (API 24) for security reasons. The only way for non-system apps to toggle airplane mode is through the `WRITE_SECURE_SETTINGS` permission, which can only be granted via ADB.

## Setup Instructions

### Step 1: Enable Developer Options

1. Open **Settings** on your Android device
2. Go to **About Phone**
3. Find **Build Number** and tap it 7 times
4. You'll see a message: "You are now a developer!"

### Step 2: Enable USB Debugging

1. Go to **Settings** > **System** > **Developer Options**
2. Enable **USB Debugging**
3. On some devices (Xiaomi/Redmi), also enable **USB Debugging (Security Settings)**

### Step 3: Download ADB Tools

Download the Android SDK Platform Tools for your computer:
- [Windows](https://dl.google.com/android/repository/platform-tools-latest-windows.zip)
- [Mac](https://dl.google.com/android/repository/platform-tools-latest-darwin.zip)
- [Linux](https://dl.google.com/android/repository/platform-tools-latest-linux.zip)

Extract the downloaded file to a folder on your computer.

### Step 4: Connect Your Device

1. Connect your Android device to your computer via USB
2. On your device, allow USB debugging when prompted
3. Open a terminal/command prompt in the platform-tools folder

### Step 5: Verify Connection

Run this command to verify your device is connected:

```bash
adb devices
```

You should see your device listed.

### Step 6: Grant Permission

Run this command to grant the required permission:

```bash
adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS
```

### Step 7: Verify in App

1. Open the Airplane Mode Scheduler app
2. Go to Settings
3. Tap "Verify Permission" to confirm the permission was granted

## Building with Codemagic

This project is configured for [Codemagic](https://codemagic.io) CI/CD. To build:

### 1. Fork/Clone this Repository

```bash
git clone https://github.com/yourusername/airplane-mode-scheduler.git
cd airplane-mode-scheduler
```

### 2. Set Up Codemagic

1. Go to [codemagic.io](https://codemagic.io) and sign in with your GitHub account
2. Add your repository to Codemagic
3. Go to **Team Settings** > **Code signing identities**
4. Add your Android Keystore:
   - Upload your keystore file or generate a new one
   - Set the keystore password, key alias, and key password
   - Give it a reference name (e.g., "airplane_scheduler_keystore")

### 3. Update codemagic.yaml

Edit the `codemagic.yaml` file and update:
- Email recipients for notifications
- Package name (if changed)
- Keystore reference name

### 4. Push to GitHub

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

### 5. Build in Codemagic

1. Go to your app in Codemagic dashboard
2. Click "Start new build"
3. Select the workflow (android-workflow or android-debug-workflow)
4. Wait for the build to complete
5. Download your APK/AAB file

## Local Development

### Requirements

- Flutter 3.16 or higher
- Dart 3.0 or higher
- Android Studio or VS Code
- Android SDK (API 21+)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/airplane-mode-scheduler.git
cd airplane-mode-scheduler
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building Release APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

### Building App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

The AAB will be at `build/app/outputs/bundle/release/app-release.aab`

## Project Structure

```
airplane_mode_scheduler/
├── android/                    # Android-specific code
│   ├── app/
│   │   ├── src/main/kotlin/   # Kotlin native code
│   │   │   └── com/airplane/scheduler/
│   │   │       ├── MainActivity.kt
│   │   │       ├── AirplaneModeManager.kt
│   │   │       ├── PermissionManager.kt
│   │   │       ├── AlarmReceiver.kt
│   │   │       ├── BootReceiver.kt
│   │   │       └── NotificationHelper.kt
│   │   └── src/main/AndroidManifest.xml
├── lib/                        # Flutter Dart code
│   ├── main.dart
│   ├── app.dart
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   └── utils/
├── codemagic.yaml             # CI/CD configuration
└── pubspec.yaml               # Dependencies
```

## Permissions Explained

| Permission | Purpose | Required |
|------------|---------|----------|
| `WRITE_SECURE_SETTINGS` | Toggle airplane mode | Yes (via ADB) |
| `SCHEDULE_EXACT_ALARM` | Schedule exact time triggers | Yes |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Run in background | Yes |
| `RECEIVE_BOOT_COMPLETED` | Reschedule after reboot | Yes |
| `WAKE_LOCK` | Keep device awake during alarm | Yes |
| `POST_NOTIFICATIONS` | Show notifications | No (optional) |

## Troubleshooting

### "Permission denied" when toggling airplane mode

1. Make sure you've granted WRITE_SECURE_SETTINGS via ADB
2. Run `adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS` again
3. Restart the app

### Alarms not firing at exact time

1. Make sure you've granted "Alarms & Reminders" permission
2. Disable battery optimization for the app
3. Check that the schedule is enabled

### App is killed in background

1. Go to Settings > Apps > Airplane Mode Scheduler > Battery
2. Set to "Unrestricted"
3. Disable any battery saver modes

### Can't find WRITE_SECURE_SETTINGS permission

Some devices (especially Samsung, Xiaomi, OPPO) may have additional restrictions:
- Check "Auto-start" permission in device settings
- Disable "MIUI Optimization" on Xiaomi devices
- Add app to "Protected apps" list

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Flutter](https://flutter.dev) - UI framework
- [Material You](https://m3.material.io/) - Design system
- [android_alarm_manager_plus](https://pub.dev/packages/android_alarm_manager_plus) - Alarm scheduling
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) - State management

## Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search existing [GitHub Issues](../../issues)
3. Create a new issue with details about your problem

---

**Note**: This app requires technical setup (ADB) due to Android security restrictions. This is intentional by Google to prevent malicious apps from controlling airplane mode without user consent.
