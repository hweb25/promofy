import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/effects.dart';

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Coming soon ✨',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final redemptions = ref.watch(myRedemptionsProvider);

    final name = profile.valueOrNull?['full_name']?.toString() ?? 'Member';
    final email = profile.valueOrNull?['email']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final loading = redemptions.isLoading;
    final claimed = redemptions.valueOrNull?.length ?? 0;
    final redeemed =
        redemptions.valueOrNull?.where((r) => r.isRedeemed).length ?? 0;
    final active =
        redemptions.valueOrNull?.where((r) => r.canRedeem).length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          SafeArea(bottom: false, child: const SizedBox(height: 12)),

          // ── Identity ────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.bannerGradient,
                        border: Border.all(color: AppTheme.accentColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.backgroundColor, width: 2),
                        ),
                        child: const Text(
                          'Member',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // ── Stat cards ──────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                value: claimed,
                label: 'Claimed',
                icon: Icons.local_offer_rounded,
                color: AppTheme.successColor,
                loading: loading,
              ),
              const SizedBox(width: 12),
              _StatCard(
                value: redeemed,
                label: 'Redeemed',
                icon: Icons.verified_rounded,
                color: AppTheme.infoColor,
                loading: loading,
              ),
              const SizedBox(width: 12),
              _StatCard(
                value: active,
                label: 'Active',
                icon: Icons.bolt_rounded,
                color: AppTheme.accentColor,
                loading: loading,
              ),
            ],
          ).animate().fadeIn(delay: 120.ms, duration: 400.ms).slideY(
              begin: 0.15, end: 0, delay: 120.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // ── Menu ────────────────────────────────────────────────────────
          _MenuTile(
            icon: Icons.confirmation_number_rounded,
            color: AppTheme.primaryColor,
            label: 'My Redemptions',
            onTap: () => _comingSoon(context),
          ),
          _MenuTile(
            icon: Icons.favorite_rounded,
            color: AppTheme.errorColor,
            label: 'Favorites',
            onTap: () => _comingSoon(context),
          ),
          _MenuTile(
            icon: Icons.notifications_rounded,
            color: AppTheme.infoColor,
            label: 'Notification Preferences',
            onTap: () => _comingSoon(context),
          ),
          _MenuTile(
            icon: Icons.storefront_rounded,
            color: AppTheme.secondaryColor,
            label: 'Switch to Business',
            onTap: () => context.go('/auth/role-select'),
          ),
          _MenuTile(
            icon: Icons.help_rounded,
            color: AppTheme.violetAccent,
            label: 'Help & Support',
            onTap: () => _comingSoon(context),
          ),

          const SizedBox(height: 14),

          // ── Log out (outlined) ──────────────────────────────────────────
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: BorderSide(
                    color: AppTheme.errorColor.withOpacity(0.4), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Log Out',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            if (loading)
              Shimmer.fromColors(
                baseColor: color.withOpacity(0.25),
                highlightColor: color.withOpacity(0.5),
                child: Container(
                  width: 26,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              )
            else
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '$v',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu tile (flat card) ───────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textLight, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
