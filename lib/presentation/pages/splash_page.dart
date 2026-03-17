import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lama/core/routing/app_routes.dart';
import 'package:lama/core/services/bootstrap_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final bootstrap = BootstrapService(prefs);

    // Minimum display time for the splash screen so it feels deliberate
    final results = await Future.wait([
      bootstrap.initialize(),
      Future.delayed(const Duration(milliseconds: 1500)), 
    ]);

    final result = results[0] as BootstrapResult;

    if (!mounted) return;

    switch (result) {
      case BootstrapResult.updateRequired:
        context.go('/forced_update');
        break;
      case BootstrapResult.onboarding:
        context.go('/onboarding');
        break;
      case BootstrapResult.home:
        context.go(AppRoutes.home);
        break;
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
      backgroundColor: const Color(0xFF09111A), // Matches premium dark theme
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2EE59D), Color(0xFF00D1FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D1FF).withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'LAMA STUDIO',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 4.0,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
