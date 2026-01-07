import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassListPage extends StatelessWidget {
  const PassListPage({super.key});

  // Helper to format timestamps into readable dates
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

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
                  Icon(Icons.folder_open, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No applications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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

              // Retrieve Fields
              String displayPlate = data['plateNumber'] ?? data['vehicleNo'] ?? '-';
              
              // 1. Calculate Period Time string
              final Timestamp? startTs = data['startDate'];
              final Timestamp? expiryTs = data['expiryDate'];
              String periodTime = "${_formatDate(startTs)} - ${_formatDate(expiryTs)}";

              return _ApplicationCard(
                vehicleNo: displayPlate,
                vehicleType: data['vehicleType'] ?? '-',
                duration: data['duration'] ?? '-',
                status: data['status'] ?? 'Pending',
                date: data['createdAt'],
                period: periodTime, // Pass the period string
                onDelete: () async {
                  // 2. Logic to delete the document
                  final confirm = await _confirmDelete(context, data['status'] == 'Pending');
                  if (confirm) {
                    await doc.reference.delete();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, bool isPending) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(isPending ? 'Cancel Application' : 'Delete Vehicle'),
            content: Text(isPending 
              ? 'Are you sure you want to cancel this application?' 
              : 'Are you sure you want to delete this vehicle record? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes', style: TextStyle(color: Colors.white)),
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
  final String period; // New field for Period Time
  final VoidCallback onDelete; // Changed from onCancel to onDelete to handle all states

  const _ApplicationCard({
    required this.vehicleNo,
    required this.vehicleType,
    required this.duration,
    required this.status,
    required this.date,
    required this.period,
    required this.onDelete,
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

  IconData get vehicleIcon {
    if (vehicleType == 'Motorcycle') {
      return Icons.two_wheeler;
    }
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    // Determine button label based on status
    final isPending = status == 'Pending';
    final buttonLabel = isPending ? 'Cancel Application' : 'Delete Vehicle';
    final buttonIcon = isPending ? Icons.cancel : Icons.delete_outline;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(vehicleIcon, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  vehicleNo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            _buildInfoRow(Icons.category_outlined, 'Type: $vehicleType'),
            _buildInfoRow(Icons.timelapse, 'Duration: $duration'),
            // 3. Display the Period Time
            _buildInfoRow(Icons.date_range, 'Period: $period'),
            _buildInfoRow(Icons.history, 'Applied: ${date.toDate().toString().split(' ')[0]}'),
            
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(buttonIcon, color: Colors.red),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}