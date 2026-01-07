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

  void _showMsg(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign Up for Free',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                '“$randomQuote”',
                style: TextStyle(
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

              // 🔐 PASSWORD
              TextField(
                controller: passCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 characters)',
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

              // 🔘 SIGN UP
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final email = emailCtrl.text.trim();
                    final password = passCtrl.text.trim();

                    // ❌ EMPTY
                    if (email.isEmpty || password.isEmpty) {
                      _showMsg(
                        'Please fill all fields',
                        color: scheme.error,
                      );
                      return;
                    }

                    // ❌ PASSWORD < 6
                    if (password.length < 6) {
                      _showMsg(
                        'Password must be at least 6 characters',
                        color: scheme.error,
                      );
                      return;
                    }

                    try {
                      final cred = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(cred.user!.uid)
                          .set({
                        'email': email,
                        'username': email.split('@')[0],
                        'createdAt': Timestamp.now(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        _showMsg(
                          'Account created successfully',
                          color: Colors.green,
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String msg = 'Registration failed';

                      if (e.code == 'email-already-in-use') {
                        msg = 'Email already registered';
                      } else if (e.code == 'invalid-email') {
                        msg = 'Invalid email format';
                      } else if (e.code == 'weak-password') {
                        msg =
                            'Password must be at least 6 characters';
                      }

                      _showMsg(msg, color: scheme.error);
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
