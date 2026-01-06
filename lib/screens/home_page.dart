import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
// import '../admin/admin_home_page.dart'; // Uncomment if you have this file
import 'apply_pass_page.dart';
import 'pass_list_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'guidelines_page.dart';

// 🔑 LIST OF ADMIN EMAILS
const List<String> adminEmails = [
  'admin@vehiclepass.com',
];

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
              // 👋 WELCOME CARD
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

              // 🚗 MY VEHICLES (Dropdown + Details)
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
                      // 1. Dropdown List
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

              // ⚠️ EXPIRY REMINDER
              _ExpiryReminder(userId: user.uid),

              const SizedBox(height: 24),

              // 💡 TIPS
              const _TipsCard(),

              const SizedBox(height: 30),

              // 🕒 RECENT APPLICATION
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
    final vehicleType = data['vehicleType'] ?? 'Car';

    // 🔹 Icon Logic
    IconData vehicleIcon = vehicleType == 'Motorcycle' 
        ? Icons.two_wheeler 
        : Icons.directions_car;

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
          vehicleIcon,
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
        final vehicleType = data['vehicleType'] ?? 'Car';

        IconData vehicleIcon = vehicleType == 'Motorcycle' 
            ? Icons.two_wheeler 
            : Icons.directions_car;

        return Card(
          child: ListTile(
            leading: Icon(vehicleIcon),
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
              Navigator.pop(ctx); 
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
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

  // 📞 FUNCTION: Show Support Dialog
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 10),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help with your application?'),
            const SizedBox(height: 16),
            _buildContactRow(Icons.email, 'support@vehiclepass.com'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.phone, '+60 12-345 6789'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.access_time, 'Mon-Fri, 9AM - 5PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // 📜 FUNCTION: Show Terms & Privacy Dialog
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Terms of Service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'By using the VehiclePass application, you agree to comply with all campus regulations regarding vehicle access and parking. You are responsible for ensuring that your vehicle details are accurate and that your pass is used only for the registered vehicle.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'We value your privacy. The data collected (including your vehicle plate number, email, and student ID) is used solely for the purpose of managing vehicle access and campus security. We do not share your personal information with third parties without your consent, except as required by law.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '3. Data Retention',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your application data will be retained for the duration of your active pass and for record-keeping purposes as mandated by the university administration.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = adminEmails.contains(email.toLowerCase());

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
            onTap: () { 
              // Do nothing (stay on drawer) or close explicitly if desired
            },
          ),

          // 🚗 Apply Vehicle Pass
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Apply Vehicle Pass'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyPassPage()),
              );
            },
          ),

          // 📄 My Applications
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('My Applications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PassListPage()),
              );
            },
          ),

          const Divider(),

          // 🔔 Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),

          // 📘 Guidelines
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Guidelines / FAQ'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuidelinesPage()),
              );
            },
          ),

          // 📞 Contact Support
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contact Support'),
            onTap: () => _showSupportDialog(context),
          ),

          // 🛡️ Terms & Privacy (Updated to be Functional)
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Terms & Privacy'),
            onTap: () => _showTermsDialog(context),
          ),

          const Divider(),

          // 🔐 Admin Dashboard (Only visible to Admins)
          if (isAdmin) 
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
              title: const Text('Admin Dashboard', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              onTap: () {
                // Uncomment below if you have AdminHomePage imported
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
              },
            ),

          // 👤 Profile
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
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
              _showLogoutDialog(context); 
            },
          ),
          
          // Version Info
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}