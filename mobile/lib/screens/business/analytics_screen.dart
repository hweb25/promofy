import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/business_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(myBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (v) {},
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: business.when(
        data: (biz) {
          if (biz == null) {
            return const Center(child: Text('Set up your business first'));
          }

          final analytics = ref.watch(businessAnalyticsProvider(biz.id));

          return analytics.when(
            data: (data) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main stats
                  const Text('Performance Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Funnel visualization
                  _FunnelCard(
                    steps: [
                      _FunnelStep(
                        label: 'Notifications Sent',
                        value: data['total_notifications_sent'] ?? 0,
                        color: AppTheme.primaryColor,
                        icon: Icons.notifications_active,
                      ),
                      _FunnelStep(
                        label: 'Notifications Opened',
                        value: data['notifications_opened'] ?? 0,
                        color: AppTheme.accentColor,
                        icon: Icons.visibility,
                      ),
                      _FunnelStep(
                        label: 'Offers Claimed',
                        value: data['total_redemptions'] ?? 0,
                        color: AppTheme.secondaryColor,
                        icon: Icons.local_offer,
                      ),
                      _FunnelStep(
                        label: 'Offers Redeemed',
                        value: data['confirmed_redemptions'] ?? 0,
                        color: AppTheme.successColor,
                        icon: Icons.check_circle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Rate cards
                  Row(
                    children: [
                      _RateCard(
                        title: 'Open Rate',
                        rate: '${data['open_rate'] ?? 0}%',
                        subtitle: 'of notifications opened',
                        color: AppTheme.accentColor,
                        icon: Icons.open_in_new,
                      ),
                      const SizedBox(width: 12),
                      _RateCard(
                        title: 'Conversion',
                        rate: '${data['conversion_rate'] ?? 0}%',
                        subtitle: 'notification to redemption',
                        color: AppTheme.successColor,
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active promotions count
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign, size: 40, color: Colors.white),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['active_promotions'] ?? 0}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'Active Promotions',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ROI Tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: AppTheme.successColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ROI Insight', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '${data['confirmed_redemptions'] ?? 0} customers visited your business through Promofy promotions.',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  final List<_FunnelStep> steps;
  const _FunnelCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    final maxValue = steps.map((s) => s.value).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: steps.map((step) {
          final ratio = step.value / maxValue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(step.icon, size: 18, color: step.color),
                    const SizedBox(width: 8),
                    Text(step.label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text('${step.value}', style: TextStyle(fontWeight: FontWeight.bold, color: step.color)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.toDouble(),
                    backgroundColor: step.color.withValues(alpha: 0.1),
                    color: step.color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FunnelStep {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  _FunnelStep({required this.label, required this.value, required this.color, required this.icon});
}

class _RateCard extends StatelessWidget {
  final String title, rate, subtitle;
  final Color color;
  final IconData icon;
  const _RateCard({required this.title, required this.rate, required this.subtitle, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(rate, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
