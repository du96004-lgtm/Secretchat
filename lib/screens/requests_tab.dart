import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';

class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      body: StreamBuilder<List<UserModel>>(
        stream: chatService.getIncomingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No incoming requests."));
          }

          final requesters = snapshot.data!;
          return ListView.builder(
            itemCount: requesters.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final requester = requesters[index];
              return Card(
                key: ValueKey(requester.uid),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: requester.avatar != null ? NetworkImage(requester.avatar!) : null,
                    child: requester.avatar == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(requester.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${requester.publicId}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          try {
                            await chatService.acceptRequest(requester.uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${requester.name} is now your friend!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          try {
                            await chatService.rejectRequest(requester.uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request rejected'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
