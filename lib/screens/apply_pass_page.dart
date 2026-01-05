import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyPassPage extends StatefulWidget {
  const ApplyPassPage({super.key});

  @override
  State<ApplyPassPage> createState() => _ApplyPassPageState();
}

class _ApplyPassPageState extends State<ApplyPassPage> {
  final vehicleNoCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();

  String vehicleType = 'Car';
  String duration = '1 Semester';
  DateTime? startDate;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Vehicle Pass'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FormCard(
              child: Column(
                children: [
                  _Field(
                    icon: Icons.directions_car,
                    child: TextField(
                      controller: vehicleNoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number',
                        hintText: 'ABC 1234',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _Field(
                    icon: Icons.category,
                    child: DropdownButtonFormField<String>(
                      value: vehicleType,
                      items: const [
                        DropdownMenuItem(
                            value: 'Car', child: Text('Car')),
                        DropdownMenuItem(
                            value: 'Motorcycle',
                            child: Text('Motorcycle')),
                      ],
                      onChanged: (v) => setState(() => vehicleType = v!),
                      decoration:
                          const InputDecoration(labelText: 'Vehicle Type'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _Field(
                    icon: Icons.timelapse,
                    child: DropdownButtonFormField<String>(
                      value: duration,
                      items: const [
                        DropdownMenuItem(
                            value: '1 Month',
                            child: Text('1 Month')),
                        DropdownMenuItem(
                            value: '1 Semester',
                            child: Text('1 Semester')),
                        DropdownMenuItem(
                            value: '1 Year', child: Text('1 Year')),
                      ],
                      onChanged: (v) => setState(() => duration = v!),
                      decoration:
                          const InputDecoration(labelText: 'Pass Duration'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _Field(
                    icon: Icons.event,
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                        ),
                        child: Text(
                          startDate == null
                              ? 'Select date'
                              : startDate!
                                  .toString()
                                  .split(' ')[0],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _Field(
                    icon: Icons.description,
                    child: TextField(
                      controller: purposeCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Purpose',
                        hintText:
                            'Example: Daily commute to campus',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(isLoading
                    ? 'Submitting...'
                    : 'Submit Application'),
                onPressed: isLoading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (vehicleNoCtrl.text.isEmpty || startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the form')),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;

    // 1. Calculate Expiry Date
    DateTime expiryDate = startDate!;
    if (duration == '1 Month') {
      expiryDate = startDate!.add(const Duration(days: 30));
    } else if (duration == '1 Semester') {
      expiryDate = startDate!.add(const Duration(days: 180)); // Approx 6 months
    } else if (duration == '1 Year') {
      expiryDate = startDate!.add(const Duration(days: 365));
    }

    await FirebaseFirestore.instance
        .collection('vehicle_passes')
        .add({
      // 2. Changed key from 'vehicleNo' to 'plateNumber' to match HomePage
      'plateNumber': vehicleNoCtrl.text.trim(), 
      'vehicleType': vehicleType,
      'duration': duration,
      'startDate': startDate,
      'expiryDate': expiryDate, // 3. Added Expiry Date to Database
      'purpose': purposeCtrl.text.trim(),
      'userEmail': user.email,
      'userId': user.uid,
      'status': 'Pending',
      'createdAt': Timestamp.now(),
    });

    setState(() => isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted')),
      );
    }
  }
}

// 🔹 UI HELPER WIDGETS
class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _Field({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}