import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_hockey,
                    size: 64,
                    color: AppColors.background,
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                    )
                    .then()
                    .shimmer(
                      duration: const Duration(milliseconds: 1500),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                
                const SizedBox(height: 40),
                
                // App Title
                Text(
                  'HOCKEY',
                  style: GoogleFonts.orbitron(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 8,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 500),
                    )
                    .slideY(begin: 0.3, end: 0),
                
                Text(
                  'SNIPE TRAINER',
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    letterSpacing: 6,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 500),
                    )
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 60),
                
                // Tagline
                Text(
                  'Light Up Your Game',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 500),
                    ),
                
                const SizedBox(height: 80),
                
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 300),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
