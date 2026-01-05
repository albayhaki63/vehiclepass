import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final bool back;

  const AppScaffold({
    super.key,
    required this.child,
    this.back = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: back ? AppBar() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDECEF),
              Color(0xFFF8F7FC),
            ],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
