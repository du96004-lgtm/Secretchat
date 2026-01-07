# SHA Certificate Fingerprints

## 🔐 Debug SHA-1 Certificate

Based on the signing report, your **Debug SHA-1** fingerprint is:

```
2E:80:1B:2C:8E:57:08:B9:C1:58:08:FE:8A:3C:6E:2A:E7:08:54:17
```

## 📝 How to Add to Firebase

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **wechat-90a23**

### Step 2: Add SHA-1 to Android App
1. Go to **Project Settings** (⚙️ icon)
2. Scroll down to **Your apps** section
3. Click on your Android app
4. Scroll to **SHA certificate fingerprints**
5. Click **Add fingerprint**
6. Paste: `2E:80:1B:2C:8E:57:08:B9:C1:58:08:FE:8A:3C:6E:2A:E7:08:54:17`
7. Click **Save**

### Step 3: Download Updated google-services.json
1. After adding SHA-1, download the updated `google-services.json`
2. Replace the file in `android/app/google-services.json`
3. Rebuild your app

## 🔑 For Release Build (Production)

When you create a release keystore for production, you'll need to:

1. Generate release keystore:
```bash
keytool -genkey -v -keystore secretchat-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias secretchat
```

2. Get SHA-1 from release keystore:
```bash
keytool -list -v -keystore secretchat-release.jks -alias secretchat
```

3. Add that SHA-1 to Firebase as well

## ✅ Current Status

- **Debug SHA-1**: `2E:80:1B:2C:8E:57:08:B9:C1:58:08:FE:8A:3C:6E:2A:E7:08:54:17`
- **Firebase Project**: wechat-90a23
- **Package Name**: com.antigravity.secretchat.secretchat

Add this SHA-1 to Firebase to enable **Google Sign-In** functionality!
