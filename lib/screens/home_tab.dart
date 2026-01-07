import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import '../widgets/add_friend_popup.dart';
import 'chat_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      body: StreamBuilder<List<UserModel>>(
        stream: chatService.getFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No friends yet. Add some!"));
          }

          final friends = snapshot.data!;
          return ListView.separated(
            itemCount: friends.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                key: ValueKey(friend.uid),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: friend.avatar != null ? NetworkImage(friend.avatar!) : null,
                      child: friend.avatar == null ? const Icon(Icons.person) : null,
                    ),
                    if (friend.online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Tap to chat"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(friend: friend),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_friend_fab",
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddFriendPopup(),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
