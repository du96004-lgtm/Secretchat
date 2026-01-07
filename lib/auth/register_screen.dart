import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join Secretchat and stay hidden.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              _buildTextField(_nameController, "Display Name", Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email", Icons.email),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, "Password", Icons.lock, isPassword: true),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_nameController.text.trim().isEmpty ||
                      _emailController.text.trim().isEmpty ||
                      _passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields"))
                    );
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    final user = await authService.signUp(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      _nameController.text.trim(),
                    );
                    setState(() => _isLoading = false);
                    
                    if (user != null) {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const MainNavigation())
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Registration Failed. Check Firebase Authentication settings."),
                          backgroundColor: Colors.red,
                        )
                      );
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      )
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
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
}
