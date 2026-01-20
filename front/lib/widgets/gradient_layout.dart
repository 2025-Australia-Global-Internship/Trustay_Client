import 'package:flutter/material.dart';

class GradientLayout extends StatelessWidget {
  final Widget child;

  const GradientLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF6B7), Color(0xFFFFFDF6)],
            ),
          ),
        ),

        SafeArea(child: child),
      ],
    );
  }
}
