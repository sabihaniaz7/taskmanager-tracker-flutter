import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskmanager/screens/main_screen.dart';
import 'package:taskmanager/utils/app_theme.dart';

/// The initial screen shown when the app launches.
///
/// It displays the app's logo/title and developer credits with smooth
/// fade and slide animations before transitioning to the [MainScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  /// Animation for the main app title and subtitle fade-in.
  late Animation<double> _fadeAnimation;
  
  /// Animation for the main app title and subtitle sliding up.
  late Animation<Offset> _slideAnimation;
  
  /// Animation for the developer credit text fade-in.
  late Animation<double> _creditFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Hide status bar for a clean, immersive splash experience.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Initial fade for the app name and slogan.
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Subtle upward slide effect for the app name.
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Fade in the developer credits slightly after the main title.
    _creditFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    
    _controller.forward();

    // Schedule navigation to the main application screen after the animations.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        // Restore standard system UI (status bar and navigation bar).
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const MainScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final primary = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Subtle background glow (Top-Left) ──────────────────
          Positioned(
            top: -100,
            left: -80,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (_, _) => Opacity(
                opacity: _fadeAnimation.value * 0.15,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),
          
          // ── Subtle background glow (Bottom-Right) ──────────────────
          Positioned(
            bottom: -120,
            right: -60,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (_, _) => Opacity(
                opacity: _fadeAnimation.value * 0.1,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),
          
          // ── Center: App Branding ───────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: _slideAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Task Manager',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        'Stay Organized. Stay Ahead.',
                        style: TextStyle(
                          fontSize: AppSizes.fontBody,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.lightSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // ── Bottom: Credits ──────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _creditFadeAnimation,
              builder: (_, _) => Opacity(
                opacity: _creditFadeAnimation.value,
                child: Column(
                  children: [
                    Text(
                      'Developed By',
                      style: TextStyle(
                        fontSize: AppSizes.fontBody,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkSecondary
                            : AppColors.lightSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      'Sabiha Niaz',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

