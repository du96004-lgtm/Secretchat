# Secretchat

A hidden real-time chat application disguised as a fully functional calculator. Built with Flutter and Firebase.

## 🎯 Features

### 🔐 Calculator Lock
- **100% Working Calculator**: Performs all basic operations (add, subtract, multiply, divide)
- **Secret PIN Protection**: Set a custom PIN on first launch
- **Perfect Disguise**: No hint that a chat app exists behind the calculator

### 💬 Real-Time Messaging
- **1-to-1 Chats**: Private conversations with friends
- **Community Chats**: Public group messaging
- **Online Status**: See who's available in real-time
- **Message History**: All messages stored in Firebase Realtime Database

### 👥 Friend System
- **5-Digit User IDs**: Unique public identifier for each user
- **QR Code Sharing**: Share your ID via QR code
- **Friend Requests**: Send and accept/reject friend requests
- **Friend List**: View all your connections with online indicators

### 📞 WebRTC Calling
- **Audio Calls**: Crystal-clear voice communication
- **Video Calls**: Face-to-face conversations
- **Call History**: Track all incoming and outgoing calls
- **Incoming Call Notifications**: Accept or reject calls in real-time

### 👤 User Profiles
- **Custom Avatars**: Upload profile pictures to Firebase Storage
- **Display Names**: Personalize your identity
- **QR Code**: Auto-generated for easy friend adding
- **Profile Management**: Edit your information anytime

### 🎨 Premium UI
- **Material 3 Design**: Modern, sleek interface
- **Dark Theme**: Easy on the eyes
- **Smooth Animations**: Polished user experience
- **Responsive Layout**: Optimized for all screen sizes

## 🛠️ Tech Stack

- **Frontend**: Flutter (latest stable with null safety)
- **State Management**: Provider
- **Backend**: Firebase
  - Authentication (Email/Password, Google Sign-In)
  - Realtime Database
  - Storage
- **Calling**: WebRTC (flutter_webrtc)
- **Encryption**: RSA-2048 (encrypt, pointycastle)
- **QR Codes**: qr_flutter
- **UI**: Material 3

## 📁 Project Structure

```
lib/
 ├── calculator_lock/    # Calculator UI & PIN logic
 ├── auth/              # Login & Registration screens
 ├── screens/           # Main app screens (Home, Calls, etc.)
 ├── widgets/           # Reusable UI components
 ├── services/          # Firebase & WebRTC services
 ├── models/            # Data models (User, Message, Call)
 ├── providers/         # State management
 └── main.dart          # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.35.6 or later)
- Firebase account
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/secretchat.git
cd secretchat
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
   - Follow the detailed instructions in [SETUP.md](SETUP.md)
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Run `flutterfire configure`

4. **Run the app**
```bash
flutter run
```

## 🔐 How to Use

### First Launch
1. App opens showing a calculator
2. Enter a 4+ digit PIN (e.g., `1234`)
3. Press `=` to set your secret PIN
4. PIN is now saved securely

### Unlocking
1. Enter your PIN on the calculator
2. Press `=`
3. If correct → Navigate to Login/Register
4. If wrong → Stay in calculator mode

### Main Features
- **Home Tab**: Chat with friends
- **Requests Tab**: Manage friend requests
- **Community Tab**: Join or create group chats
- **Calls Tab**: View call history
- **Settings Tab**: Manage profile and app settings

## 📸 Screenshots

*(Add screenshots here)*

## 🔒 Security

- **📸 Screenshot Protection**: Chat screens show blank when screenshot is attempted
- **🔔 Screenshot Detection**: Alerts users when screenshots are detected
- PIN stored as SHA-256 hash using `crypto` package
- Firebase security rules enforce auth-based access
- User data encrypted in transit
- No plaintext password storage

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- WebRTC community for calling functionality

## 📞 Support

For issues and questions, please open an issue on GitHub.

---

**Made with ❤️ using Flutter**
