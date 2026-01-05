import 'package:flutter/material.dart';

class GuidelinesPage extends StatelessWidget {
  const GuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guidelines & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _GuideTile(
            icon: Icons.verified_user,
            title: 'Eligibility',
            text:
                'Only registered students are eligible to apply for a vehicle pass.',
          ),
          _GuideTile(
            icon: Icons.timer,
            title: 'Approval Duration',
            text:
                'Applications are usually processed within 1–3 working days.',
          ),
          _GuideTile(
            icon: Icons.cancel,
            title: 'Cancellation',
            text:
                'Applications can only be cancelled while the status is Pending.',
          ),
          _GuideTile(
            icon: Icons.directions_car,
            title: 'Vehicle Rules',
            text:
                'Each student is allowed to register only one vehicle at a time.',
          ),
          _GuideTile(
            icon: Icons.help_outline,
            title: 'Need Help?',
            text:
                'Please contact the campus security office for assistance.',
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _GuideTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).primaryColor),
        title: Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(text),
      ),
    );
  }
}
