import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/business_provider.dart';
import '../../providers/promotion_provider.dart';

class BusinessHomeScreen extends ConsumerWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(myBusinessProvider);

    return business.when(
      data: (biz) {
        if (biz == null) {
          return _BusinessSetupPrompt();
        }

        final analytics = ref.watch(businessAnalyticsProvider(biz.id));
        final promotions = ref.watch(businessPromotionsProvider(biz.id));

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              biz.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _tierColor(biz.subscriptionTier).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${biz.subscriptionTier.toUpperCase()} Plan',
                                style: TextStyle(
                                  color: _tierColor(biz.subscriptionTier),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => context.go('/business/profile'),
                      ),
                    ],
                  ),
                ),
              ),

              // Analytics Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: analytics.when(
                    data: (data) => Column(
                      children: [
                        Row(
                          children: [
                            _MetricCard(
                              label: 'Notifications\nSent',
                              value: '${data['total_notifications_sent'] ?? 0}',
                              icon: Icons.notifications,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              label: 'Opened',
                              value: '${data['notifications_opened'] ?? 0}',
                              icon: Icons.visibility,
                              color: AppTheme.accentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MetricCard(
                              label: 'Redemptions',
                              value: '${data['confirmed_redemptions'] ?? 0}',
                              icon: Icons.check_circle,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              label: 'Conversion\nRate',
                              value: '${data['conversion_rate'] ?? 0}%',
                              icon: Icons.trending_up,
                              color: AppTheme.secondaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle,
                            label: 'Create\nPromotion',
                            color: AppTheme.primaryColor,
                            onTap: () => context.push('/business/promotions/create'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.qr_code_scanner,
                            label: 'Scan\nQR Code',
                            color: AppTheme.accentColor,
                            onTap: () => context.go('/business/scanner'),
                          ),
                          const SizedBox(width: 12),
                          _QuickAction(
                            icon: Icons.workspace_premium,
                            label: 'Upgrade\nPlan',
                            color: AppTheme.secondaryColor,
                            onTap: () => context.push('/business/subscription'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Active Promotions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Promotions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () => context.push('/business/promotions/create'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                ),
              ),

              promotions.when(
                data: (promos) {
                  if (promos.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.campaign_outlined, size: 64, color: AppTheme.textLight),
                            SizedBox(height: 16),
                            Text('No promotions yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Text('Create your first promotion to start attracting customers!',
                              style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = promos[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: _statusColor(p.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_statusIcon(p.status), color: _statusColor(p.status)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('${p.currentRedemptions} redeemed',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(p.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.status.toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(p.status)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: promos.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'gold': return const Color(0xFFFFD700);
      case 'premium': return AppTheme.primaryColor;
      default: return AppTheme.textSecondary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppTheme.successColor;
      case 'paused': return AppTheme.warningColor;
      case 'expired': return AppTheme.textLight;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'active': return Icons.play_circle;
      case 'paused': return Icons.pause_circle;
      case 'expired': return Icons.stop_circle;
      default: return Icons.edit;
    }
  }
}

class _BusinessSetupPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            const Text('Set Up Your Business', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Create your business profile to start publishing promotions.',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => context.go('/business/profile'), child: const Text('Get Started')),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
