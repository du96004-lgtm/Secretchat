import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/community_service.dart';

class CreateCommunityPopup extends StatefulWidget {
  const CreateCommunityPopup({super.key});

  @override
  State<CreateCommunityPopup> createState() => _CreateCommunityPopupState();
}

class _CreateCommunityPopupState extends State<CreateCommunityPopup> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final communityService = Provider.of<CommunityService>(context, listen: false);

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Create Community", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Community Name",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Description (Optional)",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (_nameController.text.isNotEmpty) {
              setState(() => _isLoading = true);
              await communityService.createCommunity(_nameController.text, _descController.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create"),
        ),
      ],
    );
  }
}
