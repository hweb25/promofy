import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promotion_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final redemptions = ref.watch(myRedemptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (profile.valueOrNull?['full_name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.valueOrNull?['full_name'] ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                _StatCard(
                  label: 'Claimed',
                  value: '${redemptions.valueOrNull?.length ?? 0}',
                  icon: Icons.local_offer,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Redeemed',
                  value: '${redemptions.valueOrNull?.where((r) => r.isRedeemed).length ?? 0}',
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Menu items
            _MenuItem(icon: Icons.history, label: 'My Redemptions', onTap: () {}),
            _MenuItem(icon: Icons.favorite_outline, label: 'Favorites', onTap: () {}),
            _MenuItem(icon: Icons.notifications_outlined, label: 'Notification Preferences', onTap: () {}),
            _MenuItem(icon: Icons.store, label: 'Switch to Business', onTap: () => context.go('/auth/role-select')),
            _MenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
            _MenuItem(icon: Icons.info_outline, label: 'About Promofy', onTap: () {}),
            const SizedBox(height: 16),
            _MenuItem(
              icon: Icons.logout,
              label: 'Sign Out',
              color: AppTheme.errorColor,
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textSecondary),
      title: Text(label, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color ?? AppTheme.textLight),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
