import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text(
                'How will you\nuse Promofy?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can always switch later',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),

              // Consumer Card
              _RoleCard(
                icon: Icons.shopping_bag_rounded,
                title: 'I\'m a Customer',
                description: 'Discover deals, get notifications, and save money at local spots.',
                color: AppTheme.primaryColor,
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.updateProfile({'role': 'consumer'});
                  if (context.mounted) context.go('/consumer');
                },
              ),
              const SizedBox(height: 20),

              // Business Card
              _RoleCard(
                icon: Icons.store_rounded,
                title: 'I\'m a Business Owner',
                description: 'Create promotions, attract customers, and grow your business.',
                color: AppTheme.secondaryColor,
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.updateProfile({'role': 'business_owner'});
                  if (context.mounted) context.go('/business');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
