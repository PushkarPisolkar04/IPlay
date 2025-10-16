import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Splash Screen - Clean design without gradients
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Bounce from top to center
    _bounceAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut,
      ),
    );

    // Scale pop effect
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Longer duration - 3 seconds total
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;

    try {
      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      
      print('🔍 Splash: User authentication status: ${user != null ? "Logged in" : "Not logged in"}');
      
      if (user != null) {
        // User is logged in, go to main screen
        print('📱 Splash: Navigating to main screen');
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // Not logged in, go to auth screen (sign in or create account)
        print('🔐 Splash: Navigating to auth screen');
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      print('❌ Splash navigation error: $e');
      // On error, default to auth screen
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/background1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.3),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // Bouncing logo from top to center
                  Positioned(
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).size.height * (0.5 + _bounceAnimation.value) - 100,
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Image.asset(
                          'assets/logos/logo.png',
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
