# 🔥 Firebase Database Cleanup Guide

## Problem: App crashes due to corrupted data in Firebase

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select project: **wechat-90a23**
3. Go to **Realtime Database**

### Step 2: Check Current Data Structure

Look for these paths and check data types:

```
friends/
  userId/
    friendId: ??? (should be Map or boolean)
    
publicIds/
  12345: "userId" (should be String)
  
users/
  userId/
    name: "..."
    email: "..."
    publicId: "12345"
```

### Step 3: Clean Corrupted Data

**Option A: Delete All Test Data (Recommended)**
1. In Realtime Database, click on root `/`
2. Click the **⋮** (three dots)
3. Select **Delete**
4. Confirm deletion

**Option B: Fix Specific Issues**

If you see:
```
friends/
  userId/
    friendId: "some string"  ❌ WRONG
```

Should be:
```
friends/
  userId/
    friendId: true  ✅ OR
    friendId:
      accepted: true
      timestamp: 1234567890
```

### Step 4: Update Security Rules

Make sure your rules are:

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
      ".write": "auth != null",
      ".validate": "newData.isString()"
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

### Step 5: Restart App

After cleaning database:
1. Uninstall app from phone
2. Clear app data
3. Run: `flutter clean`
4. Run: `flutter run -d ZD2227SDB9`

### Step 6: Test Fresh

1. Open calculator
2. Set new PIN
3. Login/Register with new account
4. Try adding friend
5. Should work without errors!

## 🚨 Quick Fix Commands

```bash
# Clean everything
flutter clean
flutter pub get

# Rebuild
flutter run -d ZD2227SDB9
```

## 📝 Important Notes

- **Delete all test data** from Firebase before testing
- **Create new user accounts** after cleanup
- **Don't reuse old user IDs** that had corrupted data
- App will work perfectly with fresh data!
