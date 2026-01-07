import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../auth/login_screen.dart';
import '../screens/edit_profile_screen.dart';

class ProfilePopup extends StatelessWidget {
  const ProfilePopup({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserModel(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final user = snapshot.data!;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: user.avatar == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                ),
                const SizedBox(height: 16),
                Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(20)),
                  child: Text("ID: ${user.publicId}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    data: user.publicId,
                    version: QrVersions.auto,
                    size: 150.0,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.deepPurpleAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Edit Profile", style: TextStyle(color: Colors.deepPurpleAccent)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await authService.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
