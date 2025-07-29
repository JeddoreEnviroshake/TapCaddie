# TapCaddie Firebase Setup Guide

This guide will walk you through setting up Firebase for the TapCaddie Flutter app, including Authentication, Firestore, and Analytics.

## Prerequisites

- Flutter SDK installed
- Android Studio with Android SDK
- Xcode (for iOS development)
- Firebase CLI installed (`npm install -g firebase-tools`)
- A Google account

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `tapcaddie` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Select your Google Analytics account
6. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable the following providers:
   - **Email/Password**: Click and toggle "Enable"
   - **Google**: Click, toggle "Enable", and add your project's SHA-1 fingerprint
   - **Apple** (iOS only): Click, toggle "Enable", configure Apple developer settings

### Getting SHA-1 Fingerprint (Android)

```bash
# For debug builds
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release builds (when you have a release keystore)
keytool -list -v -keystore /path/to/your/release-keystore.jks -alias your-key-alias
```

## Step 3: Set Up Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select your preferred location
5. Click "Done"

### Set Up Firestore Security Rules

Replace the default rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read/write their own rounds and shots
    match /rounds/{roundId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    match /shots/{shotId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Courses are readable by all authenticated users
    match /courses/{courseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Restrict in production
    }
  }
}
```

## Step 4: Add Android App

1. In Firebase Console, click "Add app" and select Android
2. Enter the following details:
   - **Android package name**: `com.yourcompany.tapcaddie`
   - **App nickname**: `TapCaddie Android`
   - **SHA-1 certificate**: (from Step 2)
3. Download `google-services.json`
4. Place the file in `android/app/` directory

### Update Android Configuration

Add these to `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.yourcompany.tapcaddie"
        minSdkVersion 21  // Required for NFC
        targetSdkVersion 34
        // ... other configurations
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-bom:32.2.2'
    implementation 'com.google.firebase:firebase-analytics'
    // ... other dependencies
}

apply plugin: 'com.google.gms.google-services'
```

Add to `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.tapcaddie">
    
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.NFC" />
    
    <!-- NFC feature -->
    <uses-feature android:name="android.hardware.nfc" android:required="false" />
    
    <application
        android:name="${applicationName}"
        android:label="TapCaddie"
        android:icon="@mipmap/ic_launcher">
        
        <!-- ... other configurations -->
        
    </application>
</manifest>
```

## Step 5: Add iOS App

1. In Firebase Console, click "Add app" and select iOS
2. Enter the following details:
   - **iOS bundle ID**: `com.yourcompany.tapcaddie`
   - **App nickname**: `TapCaddie iOS`
3. Download `GoogleService-Info.plist`
4. Drag the file into `ios/Runner/` in Xcode (ensure it's added to target)

### Update iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- ... existing keys ... -->
    
    <!-- Location permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>TapCaddie needs location access to track your golf shots and calculate distances.</string>
    
    <!-- NFC permissions -->
    <key>NFCReaderUsageDescription</key>
    <string>TapCaddie uses NFC to identify which club you're using for each shot.</string>
    
    <!-- URL schemes for Google Sign-In -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>REVERSED_CLIENT_ID</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
                <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
            </array>
        </dict>
    </array>
</dict>
```

### iOS Capabilities

Enable these in Xcode project settings:
1. Near Field Communication Tag Reading
2. Location Services

## Step 6: Configure Firebase Options

Replace the content of `lib/firebase_options.dart` with your actual Firebase configuration. You can generate this file using FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=your-project-id
```

## Step 7: Test Firebase Integration

### Test Authentication

1. Run the app: `flutter run`
2. Try registering with email/password
3. Try signing in with Google
4. Check Firebase Console > Authentication > Users

### Test Firestore

1. Complete authentication
2. Go to Profile screen and add clubs
3. Check Firebase Console > Firestore Database for user documents

## Step 8: Production Setup

### Update Security Rules

For production, update Firestore rules to be more restrictive:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /rounds/{roundId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    match /shots/{shotId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    match /courses/{courseId} {
      allow read: if request.auth != null;
      // Only allow writes from authorized users/admin
      allow write: if false; 
    }
  }
}
```

### Enable App Check (Recommended)

1. Go to Firebase Console > App Check
2. Enable App Check for both Android and iOS
3. Follow the setup instructions for your platforms

## Troubleshooting

### Common Issues

1. **SHA-1 fingerprint not matching**: Re-generate and update in Firebase Console
2. **Google Sign-In not working**: Check bundle ID and REVERSED_CLIENT_ID configuration
3. **Firestore permission denied**: Verify security rules and user authentication
4. **Location not working**: Check device permissions and app permissions

### Debug Commands

```bash
# Check Flutter dependencies
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get

# Check Firebase project
firebase projects:list
```

## Security Best Practices

1. **Never commit sensitive files**: Add `google-services.json`, `GoogleService-Info.plist` to `.gitignore`
2. **Use App Check**: Enable in production to prevent unauthorized access
3. **Restrict API keys**: Set up API key restrictions in Google Cloud Console
4. **Monitor usage**: Set up billing alerts and monitor Firebase usage
5. **Regular security reviews**: Periodically review Firestore security rules

## Development with Samsung S21 Ultra

### Enable Developer Options

1. Go to Settings > About phone
2. Tap "Build number" 7 times
3. Developer options will be enabled

### Enable USB Debugging

1. Go to Settings > Developer options
2. Enable "USB debugging"
3. Connect device via USB
4. Accept debugging authorization

### Test NFC Functionality

1. Ensure NFC is enabled: Settings > Connections > NFC and payment
2. Test with any NFC-enabled card or tag
3. Use the built-in NFC test feature in TapCaddie

### Run on Device

```bash
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Run in release mode
flutter run --release
```

## Next Steps

1. Set up continuous integration/deployment
2. Configure crash reporting with Firebase Crashlytics
3. Set up performance monitoring
4. Implement Cloud Functions for advanced features
5. Set up Firebase Extensions for additional functionality

---

For additional help, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Flutter Documentation](https://docs.flutter.dev/)