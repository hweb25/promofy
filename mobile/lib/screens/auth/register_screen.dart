import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  // Role: 'consumer' | 'business_owner'
  String _selectedRole = 'consumer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
      if (mounted) {
        context.go('/auth/role-select');
      }
    } catch (e) {
      setState(() => _error = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: size.height * 0.28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A1DB8), AppTheme.primaryColor, AppTheme.primaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Back button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: () => context.go('/auth/login'),
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

                          const SizedBox(height: 4),

                          Text(
                            'Join Promofy and never miss a deal',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.78),
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Role toggle ───────────────────────────────────────
                    Container(
                      height: 54,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          _RoleTab(
                            label: 'Consumer',
                            icon: Icons.person_rounded,
                            isSelected: _selectedRole == 'consumer',
                            onTap: () => setState(() => _selectedRole = 'consumer'),
                          ),
                          _RoleTab(
                            label: 'Business',
                            icon: Icons.storefront_rounded,
                            isSelected: _selectedRole == 'business_owner',
                            onTap: () => setState(() => _selectedRole = 'business_owner'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms),

                    const SizedBox(height: 20),

                    // Error banner
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
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
                      ).animate().fadeIn(duration: 300.ms).shakeX(),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: AppTheme.textLight, size: 20),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    )
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, delay: 80.ms, duration: 400.ms),

                    const SizedBox(height: 14),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
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
                        .fadeIn(delay: 140.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, delay: 140.ms, duration: 400.ms),

                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
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
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 14),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppTheme.textLight, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.textLight,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, delay: 260.ms, duration: 400.ms),

                    const SizedBox(height: 28),

                    // Create Account button
                    SizedBox(
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isLoading ? null : AppTheme.primaryGradient,
                          color: _isLoading
                              ? AppTheme.primaryColor.withOpacity(0.5)
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isLoading ? [] : AppTheme.floatingShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
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
                                  'Create Account',
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
                        .fadeIn(delay: 320.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, delay: 320.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // Terms note
                    Text(
                      'By creating an account, you agree to our\nTerms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppTheme.textLight,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 380.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // Sign In link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/auth/login'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 420.ms, duration: 400.ms),
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

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
