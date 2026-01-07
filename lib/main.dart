import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'calculator_lock/calculator_provider.dart';
import 'calculator_lock/calculator_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/call_service.dart';
import 'services/community_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Continue anyway - app will show error if Firebase features are used
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ChatService()),
        Provider(create: (_) => CallService()),
        Provider(create: (_) => CommunityService()),
      ],
      child: const SecretChatApp(),
    ),
  );
}

class SecretChatApp extends StatelessWidget {
  const SecretChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secretchat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.grey[900],
          indicatorColor: Colors.deepPurpleAccent.withOpacity(0.3),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}
