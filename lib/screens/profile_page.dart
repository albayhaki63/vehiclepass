import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      usernameCtrl.text = doc['username'] ?? '';
    }

    setState(() => loading = false);
  }

  Future<void> _saveUsername() async {
    if (user == null) return;

    if (usernameCtrl.text.trim().isEmpty) {
      _msg('Username cannot be empty');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set(
      {
        'username': usernameCtrl.text.trim(),
        'email': user!.email,
      },
      SetOptions(merge: true),
    );

    _msg('Username updated');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👤 HEADER
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.15),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user!.email ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ✏️ USERNAME
          const Text(
            'Username',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: usernameCtrl,
            decoration:
                const InputDecoration(hintText: 'Enter username'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveUsername,
            child: const Text('Save Username'),
          ),

          const SizedBox(height: 30),

          // 🔐 PASSWORD
          const Text(
            'Security',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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

          const Divider(height: 40),

          // 🌗 THEME
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
