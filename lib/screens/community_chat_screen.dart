import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';
import '../services/community_service.dart';

class CommunityChatScreen extends StatefulWidget {
  final CommunityModel community;
  const CommunityChatScreen({super.key, required this.community});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final communityService = Provider.of<CommunityService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.community.name, style: const TextStyle(fontSize: 18)),
            const Text("Community", style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: communityService.getCommunityMessages(widget.community.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isMe = message.senderId == communityService.currentUid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(communityService),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2),
              child: Text(message.senderId.substring(0, 5), style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.deepPurpleAccent : Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(message.timestamp)),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(CommunityService communityService) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Broadcasting to community...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.deepPurpleAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  communityService.sendCommunityMessage(widget.community.id, _messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
