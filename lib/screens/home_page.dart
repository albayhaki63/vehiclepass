import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
import 'apply_pass_page.dart';
import 'pass_list_page.dart';
import 'notifications_page.dart';
import 'guidelines_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginPage();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>;
        final username = data['username'] ?? 'User';
        final email = data['email'] ?? user.email ?? '';

        return Scaffold(
          appBar: AppBar(title: const Text('VehiclePass')),
          drawer: _AppDrawer(
            username: username,
            email: email,
          ),

          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👋 WELCOME CARD
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              Theme.of(context).primaryColor,
                          child: const Icon(Icons.person,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome 👋',
                              style:
                                  TextStyle(color: Colors.grey),
                            ),
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🚗 ACTIVE PASS (DEMO / STATIC)
                const Text(
                  'Active Vehicle Pass',
                  style:
                      TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.directions_car,
                        color: Colors.green),
                    title: const Text('Car • ABC1234'),
                    subtitle:
                        const Text('Valid until: 30 Jun 2026'),
                    trailing: Chip(
                      label: const Text('ACTIVE'),
                      backgroundColor:
                          Colors.green.shade200,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 💡 TIPS
                const Text(
                  'Tips & Reminder',
                  style:
                      TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  color: Colors.orange.shade50,
                  child: const ListTile(
                    leading: Icon(Icons.lightbulb,
                        color: Colors.orange),
                    title: Text('Renew before expiry'),
                    subtitle: Text(
                        'Renew at least 7 days before pass expires'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= DRAWER =================
class _AppDrawer extends StatelessWidget {
  final String username;
  final String email;

  const _AppDrawer({
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration:
                const BoxDecoration(color: Colors.orange),
            accountName: Text(username),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person,
                  color: Colors.orange),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading:
                const Icon(Icons.directions_car),
            title:
                const Text('Apply Vehicle Pass'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ApplyPassPage(),
                ),
              );
            },
          ),

          ListTile(
            leading:
                const Icon(Icons.receipt_long),
            title:
                const Text('My Applications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PassListPage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading:
                const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const NotificationsPage(),
                ),
              );
            },
          ),

          ListTile(
            leading:
                const Icon(Icons.menu_book),
            title:
                const Text('Guidelines / FAQ'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const GuidelinesPage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfilePage(),
                ),
              );
            },
          ),

          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout,
                color: Colors.red),
            title: const Text('Logout'),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content:
            const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => LoginPage()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
