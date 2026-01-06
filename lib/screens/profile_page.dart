import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
  File? _imageFile;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 📥 LOAD PROFILE DATA
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

  // 📸 PICK & CROP IMAGE
  Future<void> _pickImage() async {
    try {
      // 1️⃣ DEFINE primaryColor HERE (Fixes 'undefined name' error)
      final primaryColor = Theme.of(context).primaryColor;
      
      // 2️⃣ DEFINE pickedFile HERE (Fixes 'undefined name' error)
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // ✂️ Start Cropping
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path, // Now pickedFile is defined
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 70,
          maxWidth: 512,
          maxHeight: 512,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Edit Profile Picture',
              toolbarColor: primaryColor, // Now primaryColor is defined
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              showCropGrid: true, 
            ),
            IOSUiSettings(
              title: 'Edit Profile Picture',
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imageFile = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      _msg('Error picking image: $e');
    }
  }

  // ☁️ UPLOAD TO FIREBASE STORAGE
  Future<String?> _uploadImage() async {
    if (_imageFile == null || user == null) return null;

    try {
      // Create path: user_profiles/USER_ID.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${user!.uid}.jpg');

      // Upload
      await storageRef.putFile(_imageFile!);

      // Get URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      _msg('Failed to upload image: $e');
      return null;
    }
  }

  // 💾 SAVE EVERYTHING (Firestore + Auth)
  Future<void> _saveProfile() async {
    if (user == null) return;

    if (usernameCtrl.text.trim().isEmpty) {
      _msg('Username cannot be empty');
      return;
    }

    setState(() => loading = true);

    try {
      String? newPhotoUrl = _currentPhotoUrl;

      // If a new local image was picked, upload it first
      if (_imageFile != null) {
        newPhotoUrl = await _uploadImage();
      }

      // Update Firestore Document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set(
        {
          'username': usernameCtrl.text.trim(),
          'email': user!.email,
          'photoUrl': newPhotoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Update Firebase Auth Profile (Optional but recommended)
      if (newPhotoUrl != null) {
        await user!.updatePhotoURL(newPhotoUrl);
      }

      _msg('Profile updated successfully');
      
      // Refresh local state
      setState(() {
        _currentPhotoUrl = newPhotoUrl;
        _imageFile = null; // Clear local file to show the cloud URL now
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

    // Determine which image to display
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(_imageFile!); // Local picked image
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_currentPhotoUrl!); // Cloud image
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👤 AVATAR SECTION
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.15),
                  backgroundImage: backgroundImage,
                  child: backgroundImage == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                // Camera Button
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt, 
                        size: 22, 
                        color: Theme.of(context).primaryColor,
                      ),
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

          // 📝 USERNAME
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
            ),
          ),
          const SizedBox(height: 20),
          
          // 💾 SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Changes'),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),

          // 🔒 SECURITY
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

          // 🎨 THEME SETTINGS
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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