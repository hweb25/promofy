import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        final role = ref.read(userRoleProvider);
        if (role == 'business_owner') {
          context.go('/business');
        } else {
          context.go('/consumer');
        }
      }
    } catch (e) {
      setState(() => _error = 'Invalid email or password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      await ref.read(authServiceProvider).signInWithFacebook();
    } catch (e) {
      setState(() => _error = 'Facebook sign-in failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header ────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: size.height * 0.36,
              decoration: const BoxDecoration(
                gradient: AppTheme.splashGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_offer_rounded,
                          size: 40, color: AppTheme.primaryColor),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 4),

                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),

            // ── Form ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error banner
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: AppTheme.errorColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppTheme.errorColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).shakeX(duration: 400.ms),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined,
                            color: AppTheme.textLight, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: AppTheme.textLight, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textLight,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters required';
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 180.ms, duration: 400.ms),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Password reset flow
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sign In button
                    SizedBox(
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : AppTheme.primaryGradient,
                          color: _isLoading ? AppTheme.primaryColor.withOpacity(0.5) : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isLoading ? [] : AppTheme.floatingShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 260.ms, duration: 400.ms),

                    const SizedBox(height: 28),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              color: AppTheme.dividerColor, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppTheme.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                              color: AppTheme.dividerColor, thickness: 1),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.g_mobiledata,
                            label: 'Google',
                            color: const Color(0xFFDB4437),
                            onTap: _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            color: const Color(0xFF1877F2),
                            onTap: _signInWithFacebook,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 380.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 380.ms, duration: 400.ms),

                    const SizedBox(height: 36),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/auth/register'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 440.ms, duration: 400.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor, width: 1.5),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
