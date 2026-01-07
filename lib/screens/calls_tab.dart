import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/call_service.dart';
import '../models/call_model.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final callService = Provider.of<CallService>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Clear Call History?"),
              content: const Text("This will delete all your call logs permanently."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    callService.clearCallHistory();
                    Navigator.pop(context);
                  },
                  child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.delete_sweep),
      ),
      body: StreamBuilder<List<CallModel>>(
        stream: callService.getCallHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No call history."));
          }

          final calls = snapshot.data!;
          return ListView.separated(
            itemCount: calls.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final call = calls[index];
              final isMe = call.callerId == callService.currentUid;
              final name = isMe ? call.receiverName : call.callerName;
              final avatar = isMe ? call.receiverAvatar : call.callerAvatar;
              
              IconData callIcon;
              Color iconColor;
              
              if (isMe) {
                callIcon = Icons.call_made;
                iconColor = Colors.green;
              } else {
                callIcon = call.status == CallStatus.missed ? Icons.call_missed : Icons.call_received;
                iconColor = call.status == CallStatus.missed ? Colors.red : Colors.green;
              }

              return ListTile(
                key: ValueKey('${call.callerId}-${call.timestamp}'),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Call Log?"),
                      content: Text("Delete call details with $name?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            callService.deleteCallLog(call.id);
                            Navigator.pop(context);
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person) : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "${DateFormat('MMM dd, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(call.timestamp))} • ${call.type.name}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Icon(callIcon, color: iconColor),
              );
            },
          );
        },
      ),
    );
  }
}
