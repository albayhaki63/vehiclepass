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
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          username = data['username'] ?? username;
          photoUrl = data['photoUrl'];
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Home')),
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
              
              // 🚗 VEHICLE DROPDOWN & CARD
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
              
              // 🕒 RECENT APPLICATION HEADER (View All Button Removed)
              const Text('Recent Application', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _ExpiryReminder extends StatelessWidget {
  final String userId;
  const _ExpiryReminder({required this.userId});
  @override
  Widget build(BuildContext context) {
    return const SizedBox(); 
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) {
    return const Card(child: ListTile(leading: Icon(Icons.lightbulb_outline, color: Colors.amber), title: Text('Tip'), subtitle: Text('Apply early to avoid processing delays!')));
  }
}

// 🕒 RECENT APPLICATION WIDGET
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
          .limit(1) // Get only the latest one
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            color: Colors.grey[100],
            child: const ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text('No applications yet'),
              subtitle: Text('Your recent application will appear here'),
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        final plate = data['plateNumber'] ?? data['vehicleNo'] ?? 'Unknown';
        final status = data['status'] ?? 'Pending';
        final vehicleType = data['vehicleType'] ?? 'Car';
        final timestamp = data['createdAt'] as Timestamp?;
        final dateStr = timestamp != null 
            ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
            : "Unknown date";

        Color statusColor = status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange);
        IconData icon = vehicleType == 'Motorcycle' ? Icons.two_wheeler : Icons.directions_car;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(icon, color: statusColor),
            ),
            title: Text(plate, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Applied: $dateStr'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {
               // Navigate to pass list
               Navigator.push(context, MaterialPageRoute(builder: (_) => const PassListPage()));
            },
          ),
        );
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String username;
  final String email;
  final String? photoUrl; 

  const _AppDrawer({
    required this.username,
    required this.email,
    this.photoUrl,
  });

  void _showLogoutDialog(BuildContext context) {
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

  // 📞 CONTACT SUPPORT DIALOG
  void _showSupportDialog(BuildContext context) {
     showDialog(
       context: context, 
       builder: (_) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         title: Row(
           children: const [
             Icon(Icons.support_agent, color: Colors.blue),
             SizedBox(width: 10),
             Text('Support'),
           ],
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: const [
             Text('Need help? Contact our admin team below:', style: TextStyle(color: Colors.grey)),
             SizedBox(height: 20),
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Icon(Icons.email_outlined, color: Colors.orange),
               title: Text('Email'),
               subtitle: Text('support@vehiclepass.com'),
             ),
             Divider(),
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Icon(Icons.phone_outlined, color: Colors.green),
               title: Text('Hotline'),
               subtitle: Text('+60 3-8888 1234'),
             ),
             Divider(),
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: Icon(Icons.access_time, color: Colors.blueGrey),
               title: Text('Operating Hours'),
               subtitle: Text('Mon - Fri, 9:00 AM - 5:00 PM'),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context), 
             child: const Text('Close')
           ),
         ],
       )
     );
  }

  // 📜 TERMS & PRIVACY DIALOG
  void _showTermsDialog(BuildContext context) {
     showDialog(
       context: context, 
       builder: (_) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         title: const Text('Terms & Privacy'),
         content: SizedBox(
           width: double.maxFinite,
           child: SingleChildScrollView(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: const [
                 Text('Terms of Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 SizedBox(height: 10),
                 Text(
                   '1. Use of Service\nBy using this application, you agree to provide accurate and up-to-date information regarding your vehicle and identity.\n\n'
                   '2. Vehicle Pass\nThe vehicle pass generated is for the sole use of the registered vehicle and applicant. It is non-transferable.\n\n'
                   '3. Compliance\nUsers must comply with all campus traffic rules and regulations. Failure to do so may result in pass revocation.',
                   style: TextStyle(fontSize: 14, height: 1.4),
                 ),
                 SizedBox(height: 24),
                 Divider(),
                 SizedBox(height: 10),
                 Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 SizedBox(height: 10),
                 Text(
                   '1. Data Collection\nWe collect personal information such as name, email, and vehicle details solely for the purpose of processing vehicle passes.\n\n'
                   '2. Data Security\nYour data is stored securely and will not be shared with third parties without your consent, except as required by law.',
                   style: TextStyle(fontSize: 14, height: 1.4),
                 ),
               ],
             ),
           ),
         ),
         actions: [
           ElevatedButton(
             onPressed: () => Navigator.pop(context), 
             child: const Text('I Understand')
           ),
         ],
       )
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