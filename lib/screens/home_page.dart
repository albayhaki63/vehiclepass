import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_page.dart';
import 'apply_pass_page.dart';
import 'pass_list_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'guidelines_page.dart';

const List<String> adminEmails = ['admin@vehiclepass.com'];

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
        String? photoUrl; // 🔹 Variable for photo

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          username = data['username'] ?? username;
          photoUrl = data['photoUrl']; // 🔹 Fetch photoUrl
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Home')),
          // 🔹 Pass photoUrl to Drawer
          drawer: _AppDrawer(
            username: username,
            email: user.email ?? '',
            photoUrl: photoUrl, 
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
                      // 🔹 Display Profile Image here
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(Icons.person, color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome 👋', style: TextStyle(color: Colors.grey)),
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
              const Text('My Vehicles', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // ... (Keep existing Vehicle StreamBuilder code here) ...
              // For brevity, I'm hiding the vehicle list code since it hasn't changed.
              // Just ensure you keep the existing StreamBuilder<QuerySnapshot> code here.
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPassId,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardColor,
                            items: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final plate = data['plateNumber'] ?? data['vehicleNo'] ?? 'Unknown';
                              return DropdownMenuItem(value: doc.id, child: Text(plate));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPassId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSelectedVehicleCard(selectedData),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              _ExpiryReminder(userId: user.uid),
              const SizedBox(height: 24),
              const _TipsCard(),
              const SizedBox(height: 30),
              const Text('Recent Application', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _RecentApplication(userId: user.uid),
            ],
          ),
        );
      },
    );
  }

  // ... (Keep existing _buildSelectedVehicleCard, _ExpiryReminder, _TipsCard, _RecentApplication) ...
    Widget _buildSelectedVehicleCard(Map<String, dynamic> data) {
    String expiryString = 'N/A';
    if (data['expiryDate'] != null) {
      final DateTime expiry = (data['expiryDate'] as Timestamp).toDate();
      expiryString = "${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}";
    }

    final status = data['status'] ?? 'Pending';
    final plate = data['plateNumber'] ?? data['vehicleNo'] ?? 'Unknown Plate';
    final vehicleType = data['vehicleType'] ?? 'Car';
    IconData vehicleIcon = vehicleType == 'Motorcycle' ? Icons.two_wheeler : Icons.directions_car;
    Color statusColor = status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange);

    return Card(
      child: ListTile(
        leading: Icon(vehicleIcon, color: statusColor, size: 32),
        title: Text(plate, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Status: $status'), Text('Expires: $expiryString')]),
        trailing: Chip(label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: statusColor),
      ),
    );
  }
}

// ... (Keep helper classes: _ExpiryReminder, _TipsCard, _RecentApplication from previous codes) ...
class _ExpiryReminder extends StatelessWidget {
  final String userId;
  const _ExpiryReminder({required this.userId});
  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // (Placeholder to save space, assuming it's same as before)
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) {
    return const Card(child: ListTile(leading: Icon(Icons.lightbulb_outline), title: Text('Tip'), subtitle: Text('Apply early!')));
  }
}

class _RecentApplication extends StatelessWidget {
  final String userId;
  const _RecentApplication({required this.userId});
  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // (Placeholder)
  }
}

// ================= UPDATED DRAWER =================
class _AppDrawer extends StatelessWidget {
  final String username;
  final String email;
  final String? photoUrl; // 🔹 Add photoUrl

  const _AppDrawer({
    required this.username,
    required this.email,
    this.photoUrl,
  });

  void _showLogoutDialog(BuildContext context) {
    // ... (same as before) ...
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage()), (_) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
     showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Support'), content: Text('Contact support@vehiclepass.com')));
  }

  void _showTermsDialog(BuildContext context) {
     showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Terms'), content: Text('Terms content...')));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = adminEmails.contains(email.toLowerCase());

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 🔹 UPDATED HEADER WITH IMAGE
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFF9800)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, color: Color(0xFFFF9800))
                  : null,
            ),
            accountName: Text(username),
            accountEmail: Text(email),
          ),
          
          ListTile(leading: const Icon(Icons.home), title: const Text('Home'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.directions_car), title: const Text('Apply Vehicle Pass'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyPassPage()))),
          ListTile(leading: const Icon(Icons.receipt_long), title: const Text('My Applications'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassListPage()))),
          const Divider(),
          ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifications'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
          ListTile(leading: const Icon(Icons.menu_book), title: const Text('Guidelines / FAQ'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidelinesPage()))),
          ListTile(leading: const Icon(Icons.support_agent), title: const Text('Contact Support'), onTap: () => _showSupportDialog(context)),
          ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Terms & Privacy'), onTap: () => _showTermsDialog(context)),
          const Divider(),
          if (isAdmin) ListTile(leading: const Icon(Icons.admin_panel_settings, color: Colors.purple), title: const Text('Admin Dashboard', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)), onTap: () {}),
          ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), onTap: () => _showLogoutDialog(context)),
          const Padding(padding: EdgeInsets.all(16.0), child: Text('Version 1.0.0', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}