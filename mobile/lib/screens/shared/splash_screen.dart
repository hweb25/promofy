import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/supabase_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _logoController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    try {
      // Wait for Supabase to restore session from storage
      final session = SupabaseService.auth.currentSession;
      if (session != null) {
        if (mounted) context.go('/consumer');
        return;
      }

      // Session might not be restored yet — listen for auth state
      final completer = Completer<bool>();
      final subscription = SupabaseService.auth.onAuthStateChange.listen((data) {
        if (!completer.isCompleted) {
          completer.complete(data.session != null);
        }
      });

      // Wait up to 2 seconds for session restore
      final isLoggedIn = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      subscription.cancel();

      if (!mounted) return;
      if (isLoggedIn) {
        context.go('/consumer');
      } else {
        // Check shared preferences if user has completed onboarding
        final prefs = await SharedPreferences.getInstance();
        final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
        if (!mounted) return;
        if (hasOnboarded) {
          context.go('/auth/login');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Stack(
          children: [
            // Animated background circles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlePainter(_particleController.value),
                  size: MediaQuery.of(context).size,
                );
              },
            ),

            // Glow blobs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight.withOpacity(0.25),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor.withOpacity(0.18),
                ),
              ),
            ),

            // Center content
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo container
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _LogoWidget(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // App name
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: const Text(
                          'Promofy',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _taglineSlide.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              'Deals Near You',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.92),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom shimmer bar
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: const Icon(
            Icons.local_offer_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final particles = [
      _Particle(0.15, 0.20, 6, 0.0),
      _Particle(0.82, 0.14, 4, 0.3),
      _Particle(0.70, 0.75, 8, 0.6),
      _Particle(0.10, 0.65, 5, 0.1),
      _Particle(0.90, 0.50, 3, 0.8),
      _Particle(0.40, 0.10, 4, 0.45),
      _Particle(0.55, 0.88, 6, 0.2),
      _Particle(0.25, 0.45, 3, 0.7),
    ];

    for (final p in particles) {
      final phase = (progress + p.phase) % 1.0;
      final dy = math.sin(phase * math.pi * 2) * 12;
      final opacity = (0.4 + math.sin(phase * math.pi) * 0.3).clamp(0.0, 1.0);

      paint.color = Colors.white.withOpacity(opacity * 0.5);
      canvas.drawCircle(
        Offset(size.width * p.x, size.height * p.y + dy),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, radius, phase;
  const _Particle(this.x, this.y, this.radius, this.phase);
}
