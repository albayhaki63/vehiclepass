import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool obscurePassword = true;

  // 💬 QUOTES
  final List<String> quotes = [
    "Create today. Secure tomorrow.",
    "Every great journey starts here.",
    "Your access, your responsibility.",
    "Be part of a smarter campus.",
  ];

  late String randomQuote;

  @override
  void initState() {
    super.initState();
    randomQuote = quotes[Random().nextInt(quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              Text(
                'Sign Up for Free',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // 💬 QUOTE
              Text(
                '“$randomQuote”',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // 📧 EMAIL
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: scheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔐 PASSWORD + 👁 TOGGLE
              TextField(
                controller: passCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: scheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 🔘 SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    // 🔎 BASIC VALIDATION
                    if (emailCtrl.text.isEmpty ||
                        passCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please fill all fields'),
                          backgroundColor: scheme.error,
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

                      // 💾 SAVE USER TO FIRESTORE
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
                          content:
                              Text('Account created successfully'),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String msg = 'Registration failed';

                      if (e.code == 'email-already-in-use') {
                        msg = 'Email already registered';
                      } else if (e.code == 'weak-password') {
                        msg =
                            'Password must be at least 6 characters';
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
      ),
    );
  }
}
