import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusSummary(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 16),
            Expanded(child: _buildApplications()),
          ],
        ),
      ),
    );
  }

  // ================= STATUS SUMMARY =================
  Widget _buildStatusSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicle_passes')
          .snapshots(),
      builder: (context, snapshot) {
        int pending = 0, approved = 0, rejected = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final status = doc['status'] ?? 'Pending';
            if (status == 'Approved') {
              approved++;
            } else if (status == 'Rejected') {
              rejected++;
            } else {
              pending++;
            }
          }
        }

        return Row(
          children: [
            _StatusCard('Pending', pending, Colors.orange),
            const SizedBox(width: 12),
            _StatusCard('Approved', approved, Colors.green),
            const SizedBox(width: 12),
            _StatusCard('Rejected', rejected, Colors.red),
          ],
        );
      },
    );
  }

  // ================= FILTER =================
  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];

    return Row(
      children: filters.map((f) {
        final selected = filter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: selected,
            onSelected: (_) {
              setState(() {
                filter = f;
              });
            },
            selectedColor: Colors.orange,
          ),
        );
      }).toList(),
    );
  }

  // ================= APPLICATION LIST =================
  Widget _buildApplications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicle_passes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          if (filter == 'All') return true;
          return doc['status'] == filter;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No applications'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _ApplicationCard(
              id: docs[i].id,
              vehicleNo: data['vehicleNo'] ?? '-',
              vehicleType: data['vehicleType'] ?? '-',
              email: data['userEmail'] ?? '-',
              date: data['createdAt'],
              status: data['status'] ?? 'Pending',
            );
          },
        );
      },
    );
  }

  // ================= LOGOUT CONFIRM =================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Confirm Logout'),
        content:
            const Text('Are you sure you want to log out as admin?'),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () async {
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
                  child: const Text('Logout'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= STATUS CARD =================
class _StatusCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatusCard(this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= APPLICATION CARD =================
class _ApplicationCard extends StatelessWidget {
  final String id;
  final String vehicleNo;
  final String vehicleType;
  final String email;
  final Timestamp? date;
  final String status;

  const _ApplicationCard({
    required this.id,
    required this.vehicleNo,
    required this.vehicleType,
    required this.email,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicleNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _StatusBadge(status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Type: $vehicleType'),
            Text('User: $email'),
            if (date != null)
              Text(
                'Applied: ${date!.toDate().toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.grey),
              ),
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('vehicle_passes')
                            .doc(id)
                            .update({'status': 'Approved'});
                      },
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('vehicle_passes')
                            .doc(id)
                            .update({'status': 'Rejected'});
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================= STATUS BADGE =================
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 'Approved') {
      color = Colors.green;
    } else if (status == 'Rejected') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
