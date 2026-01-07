import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    UserModel? user = await authService.getCurrentUserModel();
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = await authService.user.first.then((u) => u?.uid);

    if (uid != null) {
      String? avatarUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');
        await ref.putFile(_imageFile!);
        avatarUrl = await ref.getDownloadURL();
      }

      final updates = {
        'name': _nameController.text,
      };
      if (avatarUrl != null) {
        updates['avatar'] = avatarUrl;
      }

      await FirebaseDatabase.instance.ref('users/$uid').update(updates);
      Navigator.pop(context);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[800],
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.white54) : null,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Display Name",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
