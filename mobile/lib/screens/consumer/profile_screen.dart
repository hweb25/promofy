import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promotion_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final redemptions = ref.watch(myRedemptionsProvider);

    final name = profile.valueOrNull?['full_name'] ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final claimedCount = redemptions.valueOrNull?.length ?? 0;
    final redeemedCount =
        redemptions.valueOrNull?.where((r) => r.isRedeemed).length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Avatar Header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 14),

                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                    const SizedBox(height: 4),

                    Text(
                      profile.valueOrNull?['email'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ).animate().fadeIn(delay: 220.ms, duration: 400.ms),

                    const SizedBox(height: 28),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Row(
                        children: [
                          _StatPill(
                            value: '$claimedCount',
                            label: 'Claimed',
                            icon: Icons.local_offer_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _StatPill(
                            value: '$redeemedCount',
                            label: 'Redeemed',
                            icon: Icons.check_circle_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _StatPill(
                            value: '${claimedCount - redeemedCount}',
                            label: 'Saved',
                            icon: Icons.bookmark_rounded,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),

          // ── Settings sections ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Text(
                'My Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _MenuSection(
              items: [
                _MenuItemData(
                  icon: Icons.history_rounded,
                  label: 'My Redemptions',
                  iconColor: AppTheme.primaryColor,
                  iconBg: AppTheme.primaryColor.withOpacity(0.1),
                  onTap: () {},
                ),
                _MenuItemData(
                  icon: Icons.favorite_rounded,
                  label: 'Favorites',
                  iconColor: AppTheme.errorColor,
                  iconBg: AppTheme.errorColor.withOpacity(0.1),
                  onTap: () {},
                ),
                _MenuItemData(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Referral Program',
                  iconColor: AppTheme.warningColor,
                  iconBg: AppTheme.warningColor.withOpacity(0.1),
                  onTap: () {},
                  badge: 'NEW',
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _MenuSection(
              items: [
                _MenuItemData(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  iconColor: AppTheme.infoColor,
                  iconBg: AppTheme.infoColor.withOpacity(0.1),
                  onTap: () {},
                ),
                _MenuItemData(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFF059669).withOpacity(0.1),
                  onTap: () {},
                ),
                _MenuItemData(
                  icon: Icons.storefront_rounded,
                  label: 'Switch to Business',
                  iconColor: AppTheme.accentColor,
                  iconBg: AppTheme.accentColor.withOpacity(0.1),
                  onTap: () => context.go('/auth/role-select'),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Support',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _MenuSection(
              items: [
                _MenuItemData(
                  icon: Icons.help_rounded,
                  label: 'Help & Support',
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFF7C3AED).withOpacity(0.1),
                  onTap: () {},
                ),
                _MenuItemData(
                  icon: Icons.info_rounded,
                  label: 'About Promofy',
                  iconColor: AppTheme.textSecondary,
                  iconBg: AppTheme.textSecondary.withOpacity(0.08),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Sign out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GestureDetector(
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/auth/login');
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu section ──────────────────────────────────────────────────────────────
class _MenuItemData {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
  final String? badge;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
    this.badge,
  });
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItemData> items;

  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  onTap: item.onTap,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.badge != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textLight, size: 20),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 74,
                    endIndent: 16,
                    color: AppTheme.dividerColor,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
