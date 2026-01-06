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
  // State variables for Filter and Search
  String filter = 'All';
  String searchQuery = '';
  final searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 📊 1. STATUS CARDS
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: _buildStatusSummary(),
          ),

          // 🔍 2. SEARCH BAR
          _buildSearchBar(),

          // 🏷️ 3. FILTERS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: _buildFilterChips(),
          ),

          const SizedBox(height: 10),

          // 📋 4. APPLICATION LIST
          Expanded(child: _buildApplications()),
        ],
      ),
    );
  }

  // ================= STATUS SUMMARY =================
  Widget _buildStatusSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicle_passes').snapshots(),
      builder: (context, snapshot) {
        int pending = 0, approved = 0, rejected = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final status = doc['status'] ?? 'Pending';
            if (status == 'Approved') approved++;
            else if (status == 'Rejected') rejected++;
            else pending++;
          }
        }

        return Row(
          children: [
            _StatCard(
              label: 'Pending',
              count: pending,
              icon: Icons.hourglass_top_rounded,
              color1: const Color(0xFFFFB74D),
              color2: const Color(0xFFEF6C00),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Approved',
              count: approved,
              icon: Icons.check_circle_outline_rounded,
              color1: const Color(0xFF81C784),
              color2: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Rejected',
              count: rejected,
              icon: Icons.cancel_outlined,
              color1: const Color(0xFFE57373),
              color2: const Color(0xFFC62828),
            ),
          ],
        );
      },
    );
  }

  // ================= SEARCH BAR =================
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: searchCtrl,
        onChanged: (val) {
          setState(() {
            searchQuery = val.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search plate number or email...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchCtrl.clear();
                    setState(() => searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  // ================= FILTER CHIPS =================
  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];

    return Row(
      children: filters.map((f) {
        final isSelected = filter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data found'));
        }

        // ⚡ Client-side Filtering & Searching
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final plate = (data['plateNumber'] ?? data['vehicleNo'] ?? '').toString().toLowerCase();
          final email = (data['userEmail'] ?? '').toString().toLowerCase();
          final status = data['status'] ?? 'Pending';

          // 1. Status Filter
          final statusMatch = filter == 'All' || status == filter;

          // 2. Search Query
          final searchMatch = searchQuery.isEmpty || 
                              plate.contains(searchQuery) || 
                              email.contains(searchQuery);

          return statusMatch && searchMatch;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  'No matching applications',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final displayPlate = data['plateNumber'] ?? data['vehicleNo'] ?? '-';

            return _ApplicationCard(
              id: docs[i].id,
              vehicleNo: displayPlate,
              vehicleType: data['vehicleType'] ?? '-',
              email: data['userEmail'] ?? '-',
              date: data['createdAt'],
              status: data['status'] ?? 'Pending',
              purpose: data['purpose'],
              // Pass context to show dialogs
              onApprove: () => _approvePass(docs[i].id),
              onReject: () => _rejectPassWithReason(context, docs[i].id),
            );
          },
        );
      },
    );
  }

  // ================= LOGIC: APPROVE =================
  Future<void> _approvePass(String docId) async {
    await FirebaseFirestore.instance
        .collection('vehicle_passes')
        .doc(docId)
        .update({'status': 'Approved'});
  }

  // ================= LOGIC: REJECT WITH REASON =================
  Future<void> _rejectPassWithReason(BuildContext context, String docId) async {
    final reasonCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Expired Insurance, Unclear Photo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('vehicle_passes')
                    .doc(docId)
                    .update({
                      'status': 'Rejected',
                      'rejectionReason': reasonCtrl.text.trim(),
                    });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= LOGOUT =================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to exit the admin panel?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (_) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ================= STAT CARD WIDGET =================
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color1;
  final Color color2;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13, // Slightly smaller to prevent overflow
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= APPLICATION CARD WIDGET =================
class _ApplicationCard extends StatelessWidget {
  final String id;
  final String vehicleNo;
  final String vehicleType;
  final String email;
  final Timestamp? date;
  final String status;
  final String? purpose;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.id,
    required this.vehicleNo,
    required this.vehicleType,
    required this.email,
    required this.date,
    required this.status,
    this.purpose,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'Pending';
    final dateStr = date != null
        ? "${date!.toDate().day}/${date!.toDate().month}/${date!.toDate().year}"
        : "-";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        vehicleType == 'Motorcycle'
                            ? Icons.two_wheeler
                            : Icons.directions_car,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleNo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          vehicleType,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                _StatusBadge(status),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // BODY DETAILS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person_outline, 'Applicant', email),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today_outlined, 'Date', dateStr),
                if (purpose != null && purpose!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.notes, 'Purpose', purpose!),
                ],
              ],
            ),
          ),

          // ACTIONS (Only if Pending)
          if (isPending) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: Colors.green,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onReject,
                      icon: const Icon(Icons.highlight_off),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
    Color bg;
    IconData icon;

    if (status == 'Approved') {
      color = const Color(0xFF2E7D32);
      bg = const Color(0xFFE8F5E9);
      icon = Icons.check;
    } else if (status == 'Rejected') {
      color = const Color(0xFFC62828);
      bg = const Color(0xFFFFEBEE);
      icon = Icons.close;
    } else {
      color = const Color(0xFFEF6C00);
      bg = const Color(0xFFFFF3E0);
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}