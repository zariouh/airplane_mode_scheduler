# Quick Start Guide

## For GitHub + Codemagic Users

### Step 1: Push to GitHub

```bash
# Initialize git repository
cd airplane_mode_scheduler
git init
git add .
git commit -m "Initial commit"

# Add your GitHub repository
git remote add origin https://github.com/YOUR_USERNAME/airplane-mode-scheduler.git
git push -u origin main
```

### Step 2: Set Up Codemagic

1. Go to [codemagic.io](https://codemagic.io)
2. Sign in with your GitHub account
3. Click "Add application"
4. Select your repository

### Step 3: Configure Code Signing

1. In Codemagic, go to **Team Settings** > **Code signing identities**
2. Click **Android keystore** tab
3. Generate a new keystore:
   ```bash
   keytool -genkey -v -keystore airplane-scheduler.keystore -alias key -keyalg RSA -keysize 2048 -validity 10000
   ```
4. Upload the keystore file
5. Set reference name: `airplane_scheduler_keystore`
6. Enter keystore password, key alias, and key password

### Step 4: Update codemagic.yaml

Edit `codemagic.yaml` and update:
- Email address for notifications
- Package name (if you changed it)

### Step 5: Trigger Build

1. Push any change to trigger automatic build:
   ```bash
   git commit --allow-empty -m "Trigger build"
   git push
   ```

2. Or manually start build in Codemagic dashboard

3. Download your APK from the build artifacts

### Step 6: Install & Setup

1. Install the APK on your Android device
2. Follow the in-app permission setup
3. Grant WRITE_SECURE_SETTINGS via ADB (see README.md)

---

## For Local Development

### Prerequisites

- Flutter 3.16 or higher
- Android Studio or VS Code
- Android device or emulator (API 21+)

### Setup

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/airplane-mode-scheduler.git
cd airplane-mode-scheduler

# Install dependencies
flutter pub get

# Run on device
flutter run
```

### Build Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

---

## Device Setup (Required)

### Enable Developer Options

1. Settings > About Phone
2. Tap "Build Number" 7 times

### Enable USB Debugging

1. Settings > System > Developer Options
2. Enable "USB Debugging"

### Grant Permission via ADB

```bash
# Download platform tools from:
# https://developer.android.com/studio/releases/platform-tools

# Extract and navigate to platform-tools folder

# Connect device via USB

# Verify connection
adb devices

# Grant permission
adb shell pm grant com.airplane.scheduler android.permission.WRITE_SECURE_SETTINGS
```

---

## Troubleshooting

### Build fails in Codemagic

1. Check that `codemagic.yaml` is in root directory
2. Verify keystore is uploaded correctly
3. Check build logs for specific errors

### App crashes on startup

1. Check AndroidManifest.xml permissions
2. Verify all dependencies in pubspec.yaml
3. Check for missing native code

### Airplane mode doesn't toggle

1. Verify WRITE_SECURE_SETTINGS permission granted
2. Check exact alarm permission granted
3. Disable battery optimization for the app

---

## Need Help?

- Check [README.md](README.md) for detailed documentation
- Review [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for architecture details
- Create an issue on GitHub
