import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
import 'apply_pass_page.dart';
import 'pass_list_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'guidelines_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedPassId;

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
                            'Welcome 👋',
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

              // ｪｪ MY VEHICLES (Dropdown + Details)
              const Text(
                'My Vehicles',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehicle_passes')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, vehicleSnap) {
                  if (vehicleSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = vehicleSnap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('No Vehicles Found'),
                        subtitle: Text('Apply for a pass to see it here'),
                      ),
                    );
                  }

                  if (_selectedPassId == null || !docs.any((d) => d.id == _selectedPassId)) {
                    _selectedPassId = docs.first.id;
                  }

                  final selectedDoc = docs.firstWhere((d) => d.id == _selectedPassId);
                  final selectedData = selectedDoc.data() as Map<String, dynamic>;

                  return Column(
                    children: [
                      // 1. Dropdown List (Dark Mode Fixed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor, 
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPassId,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardColor,
                            style: Theme.of(context).textTheme.bodyLarge, 
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            items: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final plate = data['plateNumber'] ?? data['vehicleNo'] ?? 'Unknown';
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  plate,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPassId = val;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),

                      // 2. Selected Vehicle Details Card
                      _buildSelectedVehicleCard(selectedData),
                    ],
                  );
                },
              ),

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

  Widget _buildSelectedVehicleCard(Map<String, dynamic> data) {
    String expiryString = 'N/A';
    if (data['expiryDate'] != null) {
      final DateTime expiry = (data['expiryDate'] as Timestamp).toDate();
      expiryString = "${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}";
    }

    final status = data['status'] ?? 'Pending';
    final plate = data['plateNumber'] ?? data['vehicleNo'] ?? 'Unknown Plate';

    Color statusColor;
    if (status == 'Approved') {
      statusColor = Colors.green;
    } else if (status == 'Rejected') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.directions_car,
          color: statusColor,
          size: 32,
        ),
        title: Text(
          plate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            Text('Expires: $expiryString'),
          ],
        ),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: statusColor,
        ),
      ),
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
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : Theme.of(context).primaryColor.withOpacity(0.08),
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

  // 🔹 Helper function to show Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // 1. Close the dialog
              Navigator.pop(ctx); 
              
              // 2. Perform sign out
              await FirebaseAuth.instance.signOut();
              
              // 3. Navigate to Login Page (removes Drawer, Dialog, and Home)
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(),
                  ),
                  (_) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
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
          
          // 🏠 Home
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),

          // 🚗 Apply Vehicle Pass
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Apply Vehicle Pass'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ApplyPassPage(),
                ),
              );
            },
          ),

          // 📄 My Applications
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('My Applications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PassListPage(),
                ),
              );
            },
          ),

          const Divider(),

          // 🔔 Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsPage(),
                ),
              );
            },
          ),

          // 📘 Guidelines / FAQ
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Guidelines / FAQ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GuidelinesPage(),
                ),
              );
            },
          ),

          const Divider(),

          // 👤 Profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),

          // 🚪 Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // ⚠️ FIX: Removed Navigator.pop(context) from here.
              // We keep the drawer open so 'context' stays valid for the Dialog.
              _showLogoutDialog(context); 
            },
          ),
        ],
      ),
    );
  }
}