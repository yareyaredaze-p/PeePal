import 'package:flutter/material.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/ocean_background.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

/// Splash Screen - App initialization and session restoration
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize database
      setState(() => _status = 'Loading database...');
      await DatabaseService.instance.database;
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Restore session
      setState(() => _status = 'Checking session...');
      final user = await AuthService.instance.restoreSession();
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Navigate based on session
      if (mounted) {
        if (user != null) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HomeScreen(userId: user.id!, username: user.username),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OceanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: AppTheme.spacingXL),

                  // App name
                  Text(
                    'PeePal',
                    style: AppTheme.logoStyle.copyWith(
                      fontSize: 48,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Loading indicator
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Status text
                  Text(_status, style: AppTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // P² logo matching UI reference
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main P
          Text(
            'P',
            style: AppTheme.logoStyle.copyWith(
              fontSize: 80,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Superscript 2
          Positioned(
            top: 10,
            right: 10,
            child: Text(
              '²',
              style: AppTheme.logoStyle.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
