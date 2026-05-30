import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/business_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(myBusinessProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Analytics')),
      body: business.when(
        data: (biz) {
          if (biz == null) return const _NoBusiness();
          final analytics = ref.watch(businessAnalyticsProvider(biz.id));
          return analytics.when(
            data: (data) => _Content(data: data),
            loading: () => const _LoadingState(),
            error: (_, __) => _ErrorState(
              onRetry: () => ref.invalidate(businessAnalyticsProvider(biz.id)),
            ),
          );
        },
        loading: () => const _LoadingState(),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(myBusinessProvider),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Content({required this.data});

  int _i(String key) => (data[key] as num?)?.round() ?? 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
          const SizedBox(height: 16),

          // Funnel
          _FunnelCard(
            steps: [
              _FunnelStep('Notifications sent', _i('total_notifications_sent'),
                  AppTheme.primaryColor, Icons.campaign_rounded),
              _FunnelStep('Notifications opened', _i('notifications_opened'),
                  AppTheme.infoColor, Icons.visibility_rounded),
              _FunnelStep('Offers claimed', _i('total_redemptions'),
                  AppTheme.secondaryColor, Icons.local_offer_rounded),
              _FunnelStep('Offers redeemed', _i('confirmed_redemptions'),
                  AppTheme.successColor, Icons.check_circle_rounded),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
          const SizedBox(height: 16),

          // Rate cards
          Row(
            children: [
              _RateCard(
                title: 'Open rate',
                rate: '${_i('open_rate')}%',
                subtitle: 'of notifications opened',
                color: AppTheme.infoColor,
                icon: Icons.open_in_new_rounded,
              ),
              const SizedBox(width: 12),
              _RateCard(
                title: 'Conversion',
                rate: '${_i('conversion_rate')}%',
                subtitle: 'sent to redeemed',
                color: AppTheme.successColor,
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active promotions hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.campaign_rounded,
                      size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: _i('active_promotions')),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '$v',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Active promotions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ROI insight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppTheme.successColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROI insight',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        '${_i('confirmed_redemptions')} customers visited your business through Promofy promotions.',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  final List<_FunnelStep> steps;
  const _FunnelCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    final maxValue = steps
        .map((s) => s.value)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 1 << 31);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: steps.map((step) {
          final ratio = (step.value / maxValue).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(step.icon, size: 18, color: step.color),
                    const SizedBox(width: 8),
                    Text(step.label,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text('${step.value}',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            color: step.color)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio.toDouble()),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      backgroundColor: step.color.withOpacity(0.1),
                      color: step.color,
                      minHeight: 8,
                    ),
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
  _FunnelStep(this.label, this.value, this.color, this.icon);
}

class _RateCard extends StatelessWidget {
  final String title, rate, subtitle;
  final Color color;
  final IconData icon;
  const _RateCard({
    required this.title,
    required this.rate,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(rate,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary)),
            Text(subtitle,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text('Crunching your numbers…',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text("Couldn't load analytics",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBusiness extends StatelessWidget {
  const _NoBusiness();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded,
                size: 52, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text('No analytics yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Set up your business and publish a promotion to start seeing performance data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/business/profile'),
              child: const Text('Set up business'),
            ),
          ],
        ),
      ),
    );
  }
}
