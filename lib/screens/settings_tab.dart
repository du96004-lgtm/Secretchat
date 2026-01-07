import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'debug_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("App Settings", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          FutureBuilder(
            future: authService.getCurrentUserModel(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("My ID", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            snapshot.data!.publicId,
                            style: const TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.deepPurpleAccent),
                            onPressed: () {
                              // Copy to clipboard functionality can be added here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ID: ${snapshot.data!.publicId} copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Share this ID with friends to connect",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.deepPurpleAccent),
            title: const Text("Edit Profile"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.deepPurpleAccent),
            title: const Text("App Info"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Secretchat",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.security, size: 40, color: Colors.deepPurpleAccent),
                children: [
                  const Text("A secure, hidden chat application disguised as a calculator."),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text("Debug Tools"),
            subtitle: const Text("Fix database issues", style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await authService.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
