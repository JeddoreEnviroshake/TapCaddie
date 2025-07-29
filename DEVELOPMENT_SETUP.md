# TapCaddie Development Setup Guide

This guide will help you set up the TapCaddie Flutter app for development using Android Studio with your Samsung S21 Ultra.

## Prerequisites

- Windows/Mac/Linux computer
- Android Studio (latest version)
- Flutter SDK 3.0.0 or higher
- Samsung S21 Ultra with Developer Options enabled
- USB cable for device connection

## Step 1: Install Flutter and Android Studio

### Install Flutter SDK

1. Download Flutter SDK from [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Extract to a location like `C:\flutter` (Windows) or `/Users/{username}/flutter` (Mac)
3. Add Flutter to your PATH environment variable
4. Run `flutter doctor` to verify installation

### Install Android Studio

1. Download from [https://developer.android.com/studio](https://developer.android.com/studio)
2. Install with default settings
3. Install Flutter and Dart plugins:
   - Go to File → Settings → Plugins
   - Search for "Flutter" and install
   - This will also install the Dart plugin

## Step 2: Configure Samsung S21 Ultra for Development

### Enable Developer Options

1. Go to Settings → About phone
2. Tap "Build number" 7 times
3. Developer options will appear in Settings

### Enable USB Debugging

1. Go to Settings → Developer options
2. Enable "USB debugging"
3. Enable "Stay awake" (keeps screen on while charging)
4. Enable "Install via USB" (allows app installation from PC)

### Enable NFC (Important for TapCaddie)

1. Go to Settings → Connections → NFC and payment
2. Turn on NFC
3. Set Android Beam to ON (if available)

## Step 3: Set Up the Project

### Clone or Extract the Project

```bash
# If you have the project files, navigate to the project directory
cd /path/to/tapcaddie

# Verify Flutter is working
flutter doctor

# Get dependencies
flutter pub get
```

### Configure Android Settings

1. Open Android Studio
2. Open the TapCaddie project folder
3. Wait for indexing to complete
4. Open `android/local.properties` and verify Flutter SDK path:

```properties
sdk.dir=/Users/{username}/Android/sdk
flutter.sdk=/path/to/flutter
```

## Step 4: Connect Your Samsung S21 Ultra

### Physical Connection

1. Connect Samsung S21 Ultra to computer via USB
2. Select "File Transfer" mode on phone
3. Accept USB debugging authorization (first time only)

### Verify Device Recognition

In Android Studio terminal or command prompt:

```bash
# Check if device is recognized
flutter devices

# Should show something like:
# Samsung SM-G998B (mobile) • 1234567890ABCDEF • android-arm64 • Android 13 (API 33)
```

## Step 5: Firebase Configuration

Before running the app, you need to set up Firebase. Follow the detailed instructions in `FIREBASE_SETUP.md`.

### Quick Firebase Setup

1. Create a Firebase project at [https://console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app with package name `com.yourcompany.tapcaddie`
3. Download `google-services.json` and place in `android/app/`
4. Add iOS app with bundle ID `com.yourcompany.tapcaddie`
5. Download `GoogleService-Info.plist` and place in `ios/Runner/`
6. Update `lib/firebase_options.dart` with your configuration

## Step 6: Run the App

### First Run

```bash
# Ensure device is connected
flutter devices

# Run in debug mode
flutter run

# Or run in release mode for better performance
flutter run --release
```

### Using Android Studio

1. Open project in Android Studio
2. Select your Samsung S21 Ultra in the device dropdown
3. Click the green play button or press Shift+F10

## Step 7: Development Workflow

### Hot Reload

Flutter supports hot reload for quick development:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- In Android Studio, use the lightning bolt icon

### Debugging

1. Set breakpoints in Dart code
2. Run in debug mode
3. Use Android Studio's debugger tools
4. Check debug console for print statements and errors

### Testing NFC Functionality

Since NFC simulation is built-in:
1. Use the "NFC Test" button on the home screen
2. Simulate different club tags
3. Test the shot tracking workflow
4. For real NFC testing, you can use any NFC-enabled card or tag

## Step 8: Build Configuration

### Debug Build

```bash
# Build debug APK
flutter build apk --debug

# Install on connected device
flutter install
```

### Release Build

```bash
# Build release APK
flutter build apk --release

# Build release bundle for Play Store
flutter build appbundle --release
```

## Step 9: Troubleshooting Common Issues

### Device Not Recognized

1. Check USB cable (use original Samsung cable if possible)
2. Try different USB ports
3. Restart adb: `adb kill-server && adb start-server`
4. Enable "USB Debugging (Security settings)" in Developer options

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Permission Issues

If GPS or NFC not working:
1. Check app permissions in phone settings
2. Grant location and NFC permissions manually
3. Test location with: Settings → Apps → TapCaddie → Permissions

### Firebase Issues

1. Verify `google-services.json` is in correct location
2. Check SHA-1 fingerprint matches Firebase console
3. Rebuild after adding Firebase files

## Step 10: Performance Optimization for Samsung S21 Ultra

### Device-Specific Settings

1. **Battery Optimization**: Add TapCaddie to "Never sleeping apps"
2. **Background App Limits**: Disable for TapCaddie
3. **GPS Accuracy**: Set to "High accuracy" mode
4. **Screen Timeout**: Set to longer duration during development

### Development Settings

```bash
# Enable performance overlay (shows FPS)
flutter run --enable-software-rendering

# Profile performance
flutter run --profile
```

## Step 11: Testing Features

### GPS Testing

1. Go outdoors for best GPS accuracy
2. Test shot distance calculations
3. Verify location permissions are granted

### NFC Testing

1. Test with built-in NFC simulator first
2. Use actual NFC tags/cards for real testing
3. Ensure NFC is enabled on device

### Authentication Testing

1. Test email/password registration
2. Test Google Sign-In (requires SHA-1 setup)
3. Verify Firebase Authentication in console

## Useful Commands

```bash
# Check Flutter installation
flutter doctor -v

# List connected devices
flutter devices

# Run with specific device
flutter run -d DEVICE_ID

# Generate release keystore (for production)
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Get debug SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## IDE Extensions (Recommended)

### Android Studio Plugins

1. Flutter Inspector
2. Dart Data Views
3. Flutter Intl (for internationalization)
4. Flutter Snippets

### VS Code Extensions (Alternative)

1. Flutter
2. Dart
3. Flutter Widget Inspector
4. GitLens

## Performance Tips

1. **Use Release Mode**: For performance testing, always use `--release`
2. **Profile Memory**: Use `flutter run --profile` to check memory usage
3. **Monitor Battery**: Test battery drain during GPS tracking
4. **Test Different Conditions**: Indoor/outdoor, different GPS accuracy

## Next Steps

1. Follow `FIREBASE_SETUP.md` for complete Firebase configuration
2. Test all major features on your Samsung S21 Ultra
3. Set up continuous integration (optional)
4. Create release builds for distribution
5. Set up crash reporting with Firebase Crashlytics

## Support

If you encounter issues:

1. Check `flutter doctor` for environment issues
2. Verify Samsung S21 Ultra is in developer mode
3. Ensure all permissions are granted
4. Check Firebase configuration
5. Review Android Studio logs for specific errors

Happy coding! 🏌️‍♂️📱