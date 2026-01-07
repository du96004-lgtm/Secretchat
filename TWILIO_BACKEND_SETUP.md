# Firebase Functions Deployment Guide

## Prerequisites
1. Node.js installed (v18 or higher)
2. Firebase CLI installed: `npm install -g firebase-tools`
3. Firebase project initialized

## Setup Steps

### 1. Login to Firebase
```bash
firebase login
```

### 2. Initialize Firebase Functions (if not already done)
```bash
firebase init functions
```
- Select your Firebase project
- Choose JavaScript
- Install dependencies

### 3. Install Dependencies
```bash
cd functions
npm install
```

### 4. Deploy Functions
```bash
firebase deploy --only functions
```

### 5. Get Function URL
After deployment, you'll get a URL like:
```
https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/getTwilioToken
```

### 6. Update Flutter App
Copy the function URL and update it in your Flutter app's `in_call_screen.dart`:
```dart
const twilioTokenUrl = 'YOUR_FUNCTION_URL_HERE';
```

## Testing
Test the function:
```bash
curl "YOUR_FUNCTION_URL?identity=user123&roomName=test-room"
```

## Troubleshooting
- If deployment fails, check Firebase billing (Blaze plan required for external API calls)
- Verify Twilio credentials are correct
- Check Firebase Functions logs: `firebase functions:log`

## Cost
- Firebase Functions: Free tier includes 2M invocations/month
- Twilio Video: ~$0.004/minute per participant
