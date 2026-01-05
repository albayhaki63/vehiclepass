import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final PreferredSizeWidget? appBar;

  const GradientScaffold({
    super.key,
    required this.colors,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
