import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_page.dart';
import '../admin/admin_home_page.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // 🔑 EMAIL ADMIN KHAS
  final List<String> adminEmails = [
    'admin@vehiclepass.com',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 FIX: Wrapped in LayoutBuilder > SingleChildScrollView > ConstrainedBox > IntrinsicHeight
      // This pattern fixes the overflow issue while keeping the Spacer() working correctly.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),

                        // 🔰 LOGO + APP NAME
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                child: const Icon(
                                  Icons.directions_car_rounded,
                                  size: 42,
                                  color: Color(0xFFFFB703),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'VehiclePass',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Manage your campus vehicle access',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 📧 EMAIL
                        TextField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 🔐 PASSWORD
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                        ),

                        // 🔁 FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text('Forgot Password?'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordPage(),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🔘 LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            child: const Text('Login'),
                            onPressed: () async {
                              try {
                                final cred = await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                  email: emailCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                );

                                final email =
                                    cred.user!.email!.toLowerCase();

                                // 🚦 ADMIN vs USER
                                if (adminEmails.contains(email)) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminHomePage(),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HomePage(),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Invalid email or password'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),

                        const Spacer(),

                        // ➕ SIGN UP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            TextButton(
                              child: const Text('Sign Up'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignUpPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}