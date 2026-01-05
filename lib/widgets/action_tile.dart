import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title,
            style: const TextStyle(color: Colors.white)),
        subtitle:
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
