import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
import 'apply_pass_page.dart';
import 'pass_list_page.dart';
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
        String username = 'User';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          username = data['username'] ?? username;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Home')),
          drawer: _AppDrawer(
            username: username,
            email: user.email ?? '',
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 窓 WELCOME
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.15),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome 窓',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ｪｪ ACTIVE VEHICLE PASS
              const Text(
                'Active Vehicle Pass',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ActiveVehiclePass(userId: user.uid),

              const SizedBox(height: 16),

              // 竢ｰ EXPIRY REMINDER
              _ExpiryReminder(userId: user.uid),

              const SizedBox(height: 24),

              // 庁 TIPS
              const _TipsCard(),

              const SizedBox(height: 30),

              // 葡 RECENT APPLICATION
              const Text(
                'Recent Application',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RecentApplication(userId: user.uid),
            ],
          ),
        );
      },
    );
  }
}

// ================= ACTIVE VEHICLE PASS =================
class _ActiveVehiclePass extends StatelessWidget {
  final String userId;

  const _ActiveVehiclePass({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicle_passes')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Approved')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('No Active Vehicle Pass'),
              subtitle: const Text('You have no approved pass'),
            ),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        // 1. Get and Format Expiry Date
        String expiryString = 'N/A';
        if (data['expiryDate'] != null) {
          final DateTime expiry = (data['expiryDate'] as Timestamp).toDate();
          // Format: DD/MM/YYYY
          expiryString = "${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}";
        }

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.verified,
              color: Colors.green,
            ),
            // 2. Display the correct Plate Number
            title: Text(
              data['plateNumber'] ?? 'Unknown Plate',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // 3. Display the Expiry Date
            subtitle: Text('Active • Expires: $expiryString'),
            trailing: const Chip(
              label: Text(
                'ACTIVE',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          ),
        );
      },
    );
  }
}

// ================= EXPIRY REMINDER =================
class _ExpiryReminder extends StatelessWidget {
  final String userId;

  const _ExpiryReminder({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicle_passes')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'Approved')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        if (data['expiryDate'] == null) {
          return const SizedBox();
        }

        final expiry = (data['expiryDate'] as Timestamp).toDate();
        final daysLeft = expiry.difference(DateTime.now()).inDays;

        // Only show if expiring in 7 days or less, but not if already expired significantly
        if (daysLeft > 7 || daysLeft < -1) return const SizedBox();

        String msg = daysLeft < 0 
            ? 'Your pass has expired' 
            : 'Your pass will expire in $daysLeft day(s)';

        return Card(
          color: Colors.red.withOpacity(0.1),
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: const Text(
              'Pass Expiry Alert',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(msg),
          ),
        );
      },
    );
  }
}

// ================= TIPS =================
class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.08),
      child: const ListTile(
        leading: Icon(Icons.lightbulb_outline),
        title: Text(
          'Tip',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Apply at least 1 day before entering campus and ensure your plate number is correct.',
        ),
      ),
    );
  }
}

// ================= RECENT APPLICATION =================
class _RecentApplication extends StatelessWidget {
  final String userId;

  const _RecentApplication({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicle_passes')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'No application yet.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car),
            // Ensure we read 'plateNumber' here as well to match the new DB structure
            title: Text(data['plateNumber'] ?? data['vehicleNo'] ?? '-'),
            subtitle: Text('Status: ${data['status']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PassListPage(),
                ),
              );
            },
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
            decoration: const BoxDecoration(color: Color(0xFFFF9800)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Color(0xFFFF9800),
              ),
            ),
            accountName: Text(username),
            accountEmail: Text(email),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Apply Vehicle Pass'),
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
            leading: const Icon(Icons.receipt_long),
            title: const Text('My Applications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PassListPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(),
                ),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}