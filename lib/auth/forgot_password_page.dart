// auth/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your email to receive reset instructions',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text('Send Instruction'),
              onPressed: () async {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(
                  email: emailCtrl.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Reset email sent')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
