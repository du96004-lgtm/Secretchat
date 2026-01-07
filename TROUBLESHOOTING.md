# Quick Fix Guide for App Crashes

## 🔍 Common Issues & Solutions

### Issue 1: App crashes immediately after launch
**Cause**: Type mismatch in Firebase data or initialization error

**Solution**: 
1. Clear app data on device
2. Uninstall and reinstall
3. Check Firebase rules

### Issue 2: "Lost connection to device"
**Cause**: App crashes during startup

**Quick Fix**:
```bash
# Clean build
flutter clean
flutter pub get

# Build fresh APK
flutter build apk --debug

# Install manually
flutter install -d DEVICE_ID
```

### Issue 3: Type 'String' is not a subtype of 'Map'
**Status**: ✅ FIXED in latest code

The code now handles both data formats:
- Old: `friends/uid: true`
- New: `friends/uid: {accepted: true, timestamp: ...}`

## 🚀 Recommended Steps

### Step 1: Build Debug APK
```bash
flutter build apk --debug
```

### Step 2: Install on Device
```bash
# Find APK at:
build/app/outputs/flutter-apk/app-debug.apk

# Install via USB or share
```

### Step 3: Check Logs
```bash
flutter logs
```

## 🔧 If Still Crashing

### Reset Firebase Data
Go to Firebase Console → Realtime Database → Delete test data

### Clear App Data
Settings → Apps → Secretchat → Storage → Clear Data

### Rebuild from Scratch
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## 📱 Testing Checklist

- [ ] Calculator screen opens
- [ ] Can set PIN (4+ digits + =)
- [ ] PIN unlock works
- [ ] Login screen appears
- [ ] Can register/login
- [ ] Main app loads
- [ ] Can add friends
- [ ] Can accept requests
- [ ] Chat works
- [ ] Calls work

## 🆘 Emergency: Simple Test Build

If nothing works, try minimal build:
1. Comment out Firebase in main.dart
2. Test calculator only
3. Add features one by one
