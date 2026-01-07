import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/main_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Text(
                  "Secretchat",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(_emailController, "Email", Icons.email),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, "Password", Icons.lock, isPassword: true),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    final user = await authService.signIn(_emailController.text, _passwordController.text);
                    setState(() => _isLoading = false);
                    if (user != null) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed")));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.white70)),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton("assets/google.png", () async {
                      final user = await authService.signInWithGoogle();
                      if (user != null) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _socialButton(String iconPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.g_mobiledata, size: 32, color: Colors.black), // Simplified for now
      ),
    );
  }
}
