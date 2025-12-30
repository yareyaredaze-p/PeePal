import 'package:flutter/material.dart';

/// Full-screen ocean background widget
/// Used consistently across all screens for visual unity
class OceanBackground extends StatelessWidget {
  final Widget child;

  const OceanBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ocean_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Dark gradient overlay for better text readability
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
