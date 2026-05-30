import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/business.dart';
import '../../models/promotion.dart';
import '../../providers/business_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/effects.dart';

class BusinessHomeScreen extends ConsumerWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(myBusinessProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: business.when(
        data: (biz) =>
            biz == null ? const _BusinessSetupPrompt() : _Dashboard(biz: biz),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => _ErrorState(
          message: "Couldn't load your business",
          onRetry: () => ref.invalidate(myBusinessProvider),
        ),
      ),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
class _Dashboard extends ConsumerWidget {
  final Business biz;
  const _Dashboard({required this.biz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(businessAnalyticsProvider(biz.id));
    final promotions = ref.watch(businessPromotionsProvider(biz.id));

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(businessAnalyticsProvider(biz.id));
        ref.invalidate(businessPromotionsProvider(biz.id));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(biz: biz)),

          // ── Metrics ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: analytics.when(
                data: (data) => _MetricsGrid(data: data),
                loading: () => const _MetricsSkeleton(),
                error: (_, __) => _InlineError(
                  onRetry: () =>
                      ref.invalidate(businessAnalyticsProvider(biz.id)),
                ),
              ),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text('Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_rounded,
                    label: 'New Promo',
                    color: AppTheme.primaryColor,
                    onTap: () => context.push('/business/promotions/create'),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR',
                    color: AppTheme.accentColor,
                    onTap: () => context.go('/business/scanner'),
                  ),
                  const SizedBox(width: 12),
                  _QuickAction(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Upgrade',
                    color: AppTheme.secondaryColor,
                    onTap: () => context.push('/business/subscription'),
                  ),
                ],
              ),
            ),
          ),

          // ── Promotions header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Promotions',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/business/promotions/create'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
          ),

          promotions.when(
            data: (promos) {
              if (promos.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyPromotions(
                    onCreate: () =>
                        context.push('/business/promotions/create'),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PromoRow(promo: promos[index]),
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 50 * index),
                            duration: 350.ms)
                        .slideY(
                            begin: 0.12,
                            end: 0,
                            delay: Duration(milliseconds: 50 * index),
                            duration: 350.ms,
                            curve: Curves.easeOut),
                    childCount: promos.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _PromoSkeleton(),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _InlineError(
                  onRetry: () =>
                      ref.invalidate(businessPromotionsProvider(biz.id)),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

// ── Gradient header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Business biz;
  const _Header({required this.biz});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            biz.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (biz.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tierIcon(biz.subscriptionTier),
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${biz.subscriptionTier.toUpperCase()} plan',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PressableScale(
                onTap: () => context.go('/business/profile'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _tierIcon(String tier) {
    switch (tier) {
      case 'gold':
        return Icons.workspace_premium_rounded;
      case 'premium':
        return Icons.star_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}

// ── Metrics ───────────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricsGrid({required this.data});

  int _i(String key) => (data[key] as num?)?.round() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _MetricCard(
              label: 'Notifications sent',
              value: _i('total_notifications_sent'),
              icon: Icons.campaign_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            _MetricCard(
              label: 'Opened',
              value: _i('notifications_opened'),
              icon: Icons.visibility_rounded,
              color: AppTheme.infoColor,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard(
              label: 'Redemptions',
              value: _i('confirmed_redemptions'),
              icon: Icons.check_circle_rounded,
              color: AppTheme.successColor,
            ),
            const SizedBox(width: 12),
            _MetricCard(
              label: 'Conversion rate',
              value: _i('conversion_rate'),
              suffix: '%',
              icon: Icons.trending_up_rounded,
              color: AppTheme.accentColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    this.suffix = '',
    required this.icon,
    required this.color,
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
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                '$v$suffix',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget card() => Expanded(
          child: Container(
            height: 116,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E4F7),
      highlightColor: Colors.white,
      child: Column(
        children: [
          Row(children: [card(), const SizedBox(width: 12), card()]),
          const SizedBox(height: 12),
          Row(children: [card(), const SizedBox(width: 12), card()]),
        ],
      ),
    );
  }
}

// ── Quick action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Promotion row ─────────────────────────────────────────────────────────────
class _PromoRow extends StatelessWidget {
  final Promotion promo;
  const _PromoRow({required this.promo});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(promo.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon(promo.status), color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 13, color: AppTheme.accentColor),
                    const SizedBox(width: 3),
                    Text(
                      '${promo.currentRedemptions} redeemed',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(promo.status),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoSkeleton extends StatelessWidget {
  const _PromoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E4F7),
      highlightColor: Colors.white,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── Empty / setup / error states ──────────────────────────────────────────────
class _EmptyPromotions extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyPromotions({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded,
                size: 38, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text('No promotions yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Create your first promotion to start attracting nearby customers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create a promotion'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessSetupPrompt extends StatelessWidget {
  const _BusinessSetupPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 46, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text('Set up your business',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              'Create your business profile to start publishing promotions and reaching nearby customers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/business/profile'),
                child: const Text('Get started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

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
            Text(message, style: Theme.of(context).textTheme.titleMedium),
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

class _InlineError extends StatelessWidget {
  final VoidCallback onRetry;
  const _InlineError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Couldn't load this — tap to retry.",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Status helpers ────────────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppTheme.successColor;
    case 'paused':
      return AppTheme.warningColor;
    case 'expired':
      return AppTheme.textLight;
    default:
      return AppTheme.textSecondary;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'active':
      return Icons.play_circle_rounded;
    case 'paused':
      return Icons.pause_circle_rounded;
    case 'expired':
      return Icons.stop_circle_rounded;
    default:
      return Icons.edit_rounded;
  }
}

String _statusLabel(String status) =>
    status.isEmpty ? 'DRAFT' : status.toUpperCase();
