import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Sign Up for Free',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                child: const Text('Sign Up'),
                onPressed: () async {
                  // 🔎 BASIC VALIDATION
                  if (emailCtrl.text.isEmpty ||
                      passCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                      ),
                    );
                    return;
                  }

                  try {
                    // 🔐 CREATE ACCOUNT
                    final cred = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                    );

                    // 💾 SAVE USER TO FIRESTORE (FAIL-SAFE)
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(cred.user!.uid)
                        .set({
                      'email': emailCtrl.text.trim(),
                      'username':
                          emailCtrl.text.split('@')[0],
                      'createdAt': Timestamp.now(),
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully'),
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    String msg = 'Registration failed';

                    if (e.code == 'email-already-in-use') {
                      msg = 'Email already registered';
                    } else if (e.code == 'weak-password') {
                      msg = 'Password must be at least 6 characters';
                    } else if (e.code == 'invalid-email') {
                      msg = 'Invalid email format';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
