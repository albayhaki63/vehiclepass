import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassListPage extends StatelessWidget {
  const PassListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicle_passes')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // 隼 LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 隼 ERROR STATE
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // 隼 EMPTY STATE
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.folder_open,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No applications yet',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 隼 DATA LIST
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // 🔹 FIX: Retrieve 'plateNumber' preferentially, fallback to 'vehicleNo'
              String displayPlate = data['plateNumber'] ?? data['vehicleNo'] ?? '-';

              return _ApplicationCard(
                vehicleNo: displayPlate,
                vehicleType: data['vehicleType'] ?? '-',
                duration: data['duration'] ?? '-',
                status: data['status'] ?? 'Pending',
                date: data['createdAt'],
                onCancel: data['status'] == 'Pending'
                    ? () async {
                        final confirm =
                            await _confirmCancel(context);
                        if (confirm) {
                          await doc.reference.delete();
                        }
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cancel Application'),
            content: const Text(
                'Are you sure you want to cancel this application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _ApplicationCard extends StatelessWidget {
  final String vehicleNo;
  final String vehicleType;
  final String duration;
  final String status;
  final Timestamp date;
  final VoidCallback? onCancel;

  const _ApplicationCard({
    required this.vehicleNo,
    required this.vehicleType,
    required this.duration,
    required this.status,
    required this.date,
    this.onCancel,
  });

  Color get statusColor {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car,
                    color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  vehicleNo,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Type: $vehicleType'),
            Text('Duration: $duration'),
            Text(
              'Applied: ${date.toDate().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon:
                      const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Cancel Application',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: onCancel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}