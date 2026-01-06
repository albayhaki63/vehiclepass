import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    // 🔹 1. Use DefaultTabController for simpler tab management
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Alerts'), // Filters only urgent items
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehicle_passes')
              .where('userId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return _buildEmptyState();

            // 🔹 2. Generate list of notification data objects
            final allNotifications = docs.map((doc) => _NotificationModel.fromDoc(doc)).toList();
            
            // 🔹 3. Filter for Alerts (Rejected, Expired, or Expiring Soon)
            final alerts = allNotifications.where((n) => n.isUrgent).toList();

            return TabBarView(
              children: [
                _buildList(allNotifications),
                alerts.isEmpty 
                    ? _buildEmptyState(msg: "No urgent alerts") 
                    : _buildList(alerts),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<_NotificationModel> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _NotificationCard(item: items[index]),
    );
  }

  Widget _buildEmptyState({String msg = "No notifications yet"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ================= UI WIDGET =================
// 🔹 Simple card to display the notification
class _NotificationCard extends StatelessWidget {
  final _NotificationModel item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.color.withOpacity(0.1),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.body),
            const SizedBox(height: 4),
            Text(item.timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ================= DATA MODEL =================
// 🔹 Handles all logic for variety (Approved, Rejected, Expired, etc.)
class _NotificationModel {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String timeAgo;
  final bool isUrgent;

  _NotificationModel({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.timeAgo,
    required this.isUrgent,
  });

  // Factory constructor to convert Firestore document to Notification
  factory _NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final plate = data['plateNumber'] ?? data['vehicleNo'] ?? 'Vehicle';
    final status = data['status'] ?? 'Pending';
    final date = (data['createdAt'] as Timestamp).toDate();

    // 🕒 Simple Time Ago Logic
    final diff = DateTime.now().difference(date);
    String timeStr = diff.inDays > 0 ? "${diff.inDays}d ago" : "${diff.inHours}h ago";
    if (diff.inDays == 0 && diff.inHours == 0) timeStr = "Just now";

    // 1️⃣ CHECK EXPIRY (If Approved)
    if (status == 'Approved' && data['expiryDate'] != null) {
      final expiry = (data['expiryDate'] as Timestamp).toDate();
      final daysLeft = expiry.difference(DateTime.now()).inDays;

      if (daysLeft < 0) {
        return _NotificationModel(
          title: 'Pass Expired',
          body: 'Your pass for $plate has expired.',
          icon: Icons.block,
          color: Colors.red,
          timeAgo: timeStr,
          isUrgent: true,
        );
      } else if (daysLeft <= 7) {
        return _NotificationModel(
          title: 'Expiring Soon',
          body: 'Pass for $plate expires in $daysLeft days.',
          icon: Icons.warning_amber,
          color: Colors.orange,
          timeAgo: timeStr,
          isUrgent: true,
        );
      }
    }

    // 2️⃣ STANDARD STATUS CHECK
    switch (status) {
      case 'Approved':
        return _NotificationModel(
          title: 'Pass Approved',
          body: 'Your application for $plate is ready.',
          icon: Icons.check_circle,
          color: Colors.green,
          timeAgo: timeStr,
          isUrgent: false,
        );
      case 'Rejected':
        return _NotificationModel(
          title: 'Application Rejected',
          body: 'Reason: ${data['rejectionReason'] ?? 'Not specified'}',
          icon: Icons.cancel,
          color: Colors.red,
          timeAgo: timeStr,
          isUrgent: true,
        );
      default: // Pending
        return _NotificationModel(
          title: 'Application Sent',
          body: 'Request for $plate is under review.',
          icon: Icons.access_time_filled,
          color: Colors.blue,
          timeAgo: timeStr,
          isUrgent: false,
        );
    }
  }
}