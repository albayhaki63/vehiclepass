import 'dart:io'; // Import for File
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Storage
import 'package:image_picker/image_picker.dart'; // Import Image Picker

import '../main.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final usernameCtrl = TextEditingController();
  
  bool loading = true;
  File? _imageFile; // Variable to hold the picked image locally
  String? _currentPhotoUrl; // Variable to hold the URL from Firestore

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 📥 Load Profile Data (Username + Photo URL)
  Future<void> _loadProfile() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        usernameCtrl.text = data['username'] ?? '';
        
        // Load the photo URL if it exists
        if (data.containsKey('photoUrl')) {
          _currentPhotoUrl = data['photoUrl'];
        }
      }
    } catch (e) {
      _msg('Error loading profile');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // 📸 Function to Pick Image from Gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, // Resize to save storage/bandwidth
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // ☁️ Function to Upload Image to Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null || user == null) return null;

    try {
      // 1. Create a reference to the file location in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${user!.uid}.jpg');

      // 2. Upload the file
      await storageRef.putFile(_imageFile!);

      // 3. Get the Download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _msg('Failed to upload image: $e');
      return null;
    }
  }

  // 💾 Save Profile (Username + Image)
  Future<void> _saveProfile() async {
    if (user == null) return;

    if (usernameCtrl.text.trim().isEmpty) {
      _msg('Username cannot be empty');
      return;
    }

    setState(() => loading = true);

    try {
      String? newPhotoUrl = _currentPhotoUrl;

      // If user picked a new image, upload it first
      if (_imageFile != null) {
        newPhotoUrl = await _uploadImage();
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set(
        {
          'username': usernameCtrl.text.trim(),
          'email': user!.email,
          'photoUrl': newPhotoUrl, // Save the URL
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Optional: Update FirebaseAuth profile as well (best practice)
      if (newPhotoUrl != null) {
        await user!.updatePhotoURL(newPhotoUrl);
      }

      _msg('Profile updated successfully');
      
      // Refresh local state
      setState(() {
        _currentPhotoUrl = newPhotoUrl;
        _imageFile = null; // Clear local selection after upload
      });
    } catch (e) {
      _msg('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine which image to show
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(_imageFile!); // Show local picked image
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_currentPhotoUrl!); // Show cloud image
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👤 HEADER WITH IMAGE PICKER
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  backgroundImage: backgroundImage,
                  child: backgroundImage == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFFFF9800),
                        )
                      : null,
                ),
                // Camera Icon Button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Center(
            child: Text(
              user!.email ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 30),

          // 📝 USERNAME FIELD
          const Text(
            'Username',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: usernameCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter username',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          
          // 💾 SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),

          // 🔒 SECURITY SECTION
          const Text(
            'Security',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordPage(),
                ),
              );
            },
          ),

          const Divider(),

          // 🎨 THEME SECTION
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: MyApp.themeMode.value,
            onChanged: (val) {
              MyApp.themeMode.value = val!;
              setState(() {});
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: MyApp.themeMode.value,
            onChanged: (val) {
              MyApp.themeMode.value = val!;
              setState(() {});
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: MyApp.themeMode.value,
            onChanged: (val) {
              MyApp.themeMode.value = val!;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}