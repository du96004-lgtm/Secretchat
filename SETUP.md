# Secretchat - Setup Guide

## 🔥 Firebase Configuration

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project" and name it "Secretchat"
3. Follow the setup wizard

### Step 2: Enable Firebase Services

#### Authentication
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable:
   - **Email/Password**
   - **Google** (Download the SHA-1 fingerprint from your Android debug keystore)

#### Realtime Database
1. Go to **Realtime Database** → **Create Database**
2. Start in **test mode** (we'll add rules later)
3. Set the following security rules:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    },
    "publicIds": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "friends": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "requests": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null"
      }
    },
    "messages": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "communities": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "community_messages": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "calls": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "call_history": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "notifications": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null"
      }
    }
  }
}
```

#### Storage
1. Go to **Storage** → **Get Started**
2. Start in **test mode**
3. Set the following rules:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Step 3: Add Firebase to Your Flutter App

#### For Android:
1. In Firebase Console, click the Android icon
2. Register your app with package name: `com.antigravity.secretchat.secretchat`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### For iOS:
1. In Firebase Console, click the iOS icon
2. Register your app with bundle ID: `com.antigravity.secretchat.secretchat`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### Step 4: Run FlutterFire CLI
```bash
flutterfire configure
```
Select your Firebase project and platforms (Android, iOS).

## 📱 Platform-Specific Configuration

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
    
    <application ...>
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for audio/video calls</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to upload profile pictures</string>
```

### Google Sign-In Setup (Android)
1. Get your SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
```
2. Copy the SHA-1 from the debug variant
3. Add it to Firebase Console → Project Settings → Your Android App

## 🚀 Running the App

### Install Dependencies
```bash
flutter pub get
```

### Run on Device/Emulator
```bash
flutter run
```

## 🔐 Calculator Lock Usage

### First Time Setup
1. App opens with calculator screen
2. Enter any 4+ digit number (e.g., `1234`)
3. Press `=` to set your secret PIN
4. Calculator will show "PIN Set!"

### Unlocking
1. Enter your PIN (e.g., `1234`)
2. Press `=`
3. If correct, you'll be navigated to the Login screen
4. If wrong, calculator stays in calculator mode

### Reset PIN (For Testing)
Clear app data from device settings or:
```bash
flutter clean
flutter run
```

## 📝 User Flow

1. **Calculator Screen** → Enter PIN → Press `=`
2. **Login/Register** → Email/Password or Google Sign-In
3. **Main App** → 5 Tabs:
   - **Home**: Private chats with friends
   - **Requests**: Incoming friend requests
   - **Community**: Public group chats
   - **Calls**: Call history
   - **Settings**: Profile & app settings

## 🔑 Key Features

- ✅ Fully functional calculator disguise
- ✅ PIN-protected access
- ✅ Real-time 1-to-1 messaging
- ✅ Friend system with 5-digit IDs
- ✅ Community (group) chats
- ✅ WebRTC audio/video calls
- ✅ Profile with QR code
- ✅ Online/offline status
- ✅ Image upload for avatars

## 🐛 Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Firebase Not Initialized
Make sure you've run `flutterfire configure` and added the config files.

### Google Sign-In Not Working
1. Verify SHA-1 is added to Firebase Console
2. Re-download `google-services.json`
3. Rebuild the app

### WebRTC Permissions Denied
Check that permissions are properly declared in AndroidManifest.xml and Info.plist.

## 📞 Testing Calls

1. Create two accounts on different devices
2. Add each other as friends using 5-digit IDs
3. Go to chat screen
4. Tap audio/video call icon
5. Accept on the other device

---

**Built with Flutter 3.35.6 | Firebase | WebRTC**
