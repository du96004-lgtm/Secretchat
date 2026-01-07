import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';

class AddFriendPopup extends StatefulWidget {
  const AddFriendPopup({super.key});

  @override
  State<AddFriendPopup> createState() => _AddFriendPopupState();
}

class _AddFriendPopupState extends State<AddFriendPopup> {
  final _idController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Add Friend", style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _idController,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        maxLength: 5,
        decoration: InputDecoration(
          hintText: "Enter 5-digit ID",
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
          ElevatedButton(
          onPressed: _isLoading ? null : () async {
            String trimmedId = _idController.text.trim();
            if (trimmedId.length == 5) {
              setState(() => _isLoading = true);
              try {
                await chatService.sendFriendRequest(trimmedId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              } finally {
                setState(() => _isLoading = false);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid 5-digit ID")));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Add"),
        ),
      ],
    );
  }
}
