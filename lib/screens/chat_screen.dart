import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';

class ChatScreen extends StatefulWidget {
  final UserModel friend;
  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final callService = Provider.of<CallService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.friend.avatar != null ? NetworkImage(widget.friend.avatar!) : null,
              child: widget.friend.avatar == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friend.name, style: const TextStyle(fontSize: 16)),
                Text(widget.friend.online ? "Online" : "Offline", style: TextStyle(fontSize: 12, color: widget.friend.online ? Colors.green : Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              callService.makeCall(context, widget.friend, isVideo: false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              callService.makeCall(context, widget.friend, isVideo: true);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Clear Chat?"),
                    content: const Text("This will delete all messages in this chat permanently."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          chatService.clearChat(widget.friend.uid);
                          Navigator.pop(context);
                        },
                        child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: chatService.getMessages(widget.friend.uid),
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
                        bool isMe = message.senderId == chatService.currentUid;
                        return _buildMessageBubble(message, isMe, chatService);
                      },
                    );
                  },
                ),
              ),
              _buildMessageInput(chatService),
            ],
          ),
          // 🛡️ Anti-Photo Privacy Overlay
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Layer 1: Aggressive Privacy Mesh
                    CustomPaint(
                      painter: AggressivePrivacyPainter(animationValue: _animController.value),
                      size: Size.infinite,
                    ),
                    // Layer 2: Moving Digital Noise
                    Opacity(
                      opacity: 0.05,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage("https://www.transparenttextures.com/patterns/60-lines.png"),
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, ChatService chatService) {
    return GestureDetector(
      onLongPress: () {
        if (!isMe) return; 
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Message?"),
            content: const Text("Are you sure you want to delete this message?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  chatService.deleteMessage(widget.friend.uid, message.id);
                  Navigator.pop(context);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.deepPurpleAccent : Colors.grey[800],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            ),
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
      ),
    );
  }

  Widget _buildMessageInput(ChatService chatService) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 45,
                  maxHeight: 120,
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    chatService.sendMessage(widget.friend.uid, _messageController.text.trim());
                    _messageController.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AggressivePrivacyPainter extends CustomPainter {
  final double animationValue;
  AggressivePrivacyPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.4;

    // Moving high-frequency grid
    double spacing = 4.0;
    double jitter = (animationValue * 10) % spacing;

    // Diagonal lines (Left to Right)
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i + jitter, 0),
        Offset(i + size.height + jitter, size.height),
        paint,
      );
    }

    // Diagonal lines (Right to Left) with different frequency
    paint.color = Colors.white.withOpacity(0.05);
    for (double i = size.width + size.height; i > 0; i -= (spacing + 0.5)) {
      canvas.drawLine(
        Offset(i - jitter, 0),
        Offset(i - size.height - jitter, size.height),
        paint,
      );
    }

    // Horizontal interference bars (Low opacity, fast moving)
    paint.strokeWidth = 1.0;
    paint.color = Colors.white.withOpacity(0.03);
    double barPos = (animationValue * size.height * 2) % size.height;
    canvas.drawLine(Offset(0, barPos), Offset(size.width, barPos), paint);
    canvas.drawLine(Offset(0, (barPos + 50) % size.height), Offset(size.width, (barPos + 50) % size.height), paint);
  }

  @override
  bool shouldRepaint(covariant AggressivePrivacyPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

