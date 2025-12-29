import 'package:flutter/material.dart';
import 'config/themes/app_theme.dart';
import 'screens/splash/splash_screen.dart';

/// Main application widget
class PeePalApp extends StatelessWidget {
  const PeePalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeePal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
