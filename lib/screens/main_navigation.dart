import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/call_service.dart';
import 'home_tab.dart';
import 'requests_tab.dart';
import 'community_tab.dart';
import 'calls_tab.dart';
import 'settings_tab.dart';
import '../widgets/profile_popup.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CallService>(context, listen: false).listenForIncomingCalls(context);
    });
  }

  final List<Widget> _tabs = [
    const HomeTab(),
    const RequestsTab(),
    const CommunityTab(),
    const CallsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secretchat", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurpleAccent,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ProfilePopup(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: "Home"),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: "Requests"),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: "Community"),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: "Calls"),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
