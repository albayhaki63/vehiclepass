import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool _loading = false;
  String _strengthText = 'Weak';
  Color _strengthColor = Colors.red;

  // ================= PASSWORD STRENGTH =================
  void _checkStrength(String password) {
    int score = 0;

    if (password.length >= 6) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      if (score <= 1) {
        _strengthText = 'Weak';
        _strengthColor = Colors.red;
      } else if (score == 2) {
        _strengthText = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _strengthText = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  // ================= CHANGE PASSWORD =================
  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _showSnack('User not logged in');
      return;
    }

    if (_currentCtrl.text.isEmpty ||
        _newCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    // ✅ MIN 6 CHAR
    if (_newCtrl.text.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    if (_newCtrl.text != _confirmCtrl.text) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔐 RE-AUTHENTICATE
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentCtrl.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // 🔄 UPDATE PASSWORD
      await user.updatePassword(_newCtrl.text.trim());

      if (!mounted) return;

      _showSnack('Password updated successfully');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to update password';

      if (e.code == 'wrong-password') {
        msg = 'Current password is incorrect';
      } else if (e.code == 'requires-recent-login') {
        msg = 'Please login again to change password';
      } else if (e.code == 'weak-password') {
        msg = 'Password must be at least 6 characters';
      }

      _showSnack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _passwordField(
              controller: _currentCtrl,
              label: 'Current Password',
              visible: _showCurrent,
              toggle: () =>
                  setState(() => _showCurrent = !_showCurrent),
            ),

            const SizedBox(height: 16),

            _passwordField(
              controller: _newCtrl,
              label: 'New Password',
              visible: _showNew,
              onChanged: _checkStrength,
              toggle: () => setState(() => _showNew = !_showNew),
            ),

            const SizedBox(height: 6),

            // 🔐 STRENGTH
            Row(
              children: [
                const Text('Strength: '),
                Text(
                  _strengthText,
                  style: TextStyle(
                    color: _strengthColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _passwordField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              visible: _showConfirm,
              toggle: () =>
                  setState(() => _showConfirm = !_showConfirm),
            ),

            const SizedBox(height: 10),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '• Minimum 6 characters\n• Include uppercase, number or symbol',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Update Password'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PASSWORD FIELD =================
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    VoidCallback? toggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon:
              Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
