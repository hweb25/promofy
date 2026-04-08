import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/promotion_provider.dart';
import '../../models/promotion.dart';

class PromotionDetailScreen extends ConsumerStatefulWidget {
  final String promotionId;
  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  ConsumerState<PromotionDetailScreen> createState() =>
      _PromotionDetailScreenState();
}

class _PromotionDetailScreenState
    extends ConsumerState<PromotionDetailScreen> {
  bool _isClaiming = false;

  Future<void> _claimOffer() async {
    setState(() => _isClaiming = true);
    try {
      final service = ref.read(promotionServiceProvider);
      final result = await service.claimPromotion(widget.promotionId);

      if (result['success'] == true && mounted) {
        context.push('/consumer/redemption/${result['redemption_id']}');
      } else if (mounted) {
        _showSnack(result['error'] ?? 'Failed to claim offer',
            isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
        backgroundColor:
            isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoAsync =
        ref.watch(promotionDetailProvider(widget.promotionId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: promoAsync.when(
        data: (promo) => _buildContent(promo),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text('Could not load deal', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(
                    promotionDetailProvider(widget.promotionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: promoAsync.valueOrNull != null
          ? _ClaimBar(isClaiming: _isClaiming, onClaim: _claimOffer)
          : null,
    );
  }

  Widget _buildContent(Promotion promo) {
    final color = AppTheme.categoryColor(promo.businessCategory ?? '');

    return CustomScrollView(
      slivers: [
        // ── Hero header ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: color,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient
                if (promo.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: promo.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _GradientHero(color: color),
                  )
                else
                  _GradientHero(color: color),

                // Bottom gradient for readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),

                // Discount badge
                Positioned(
                  bottom: 24,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          promo.discountLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (promo.distanceMeters != null)
                  Positioned(
                    bottom: 24,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            promo.formattedDistance,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title & business card ──────────────────────────────────
                Text(
                  promo.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, duration: 400.ms),

                const SizedBox(height: 12),

                // Business info card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          AppTheme.categoryIcon(promo.businessCategory ?? ''),
                          color: color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.businessName ?? 'Local Business',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (promo.businessCategory != null)
                              Text(
                                promo.businessCategory!,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_walk_rounded,
                            size: 18, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // Description
                Text(
                  promo.description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // ── Deal details ──────────────────────────────────────────
                Text(
                  'Deal Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      _DetailTile(
                        icon: Icons.access_time_rounded,
                        iconColor: AppTheme.primaryColor,
                        label: 'Valid until',
                        value: DateFormat('MMM dd, yyyy · HH:mm')
                            .format(promo.endsAt),
                        isFirst: true,
                      ),
                      if (promo.activeTimeStart != null &&
                          promo.activeTimeEnd != null)
                        _DetailTile(
                          icon: Icons.schedule_rounded,
                          iconColor: AppTheme.infoColor,
                          label: 'Active hours',
                          value:
                              '${promo.activeTimeStart} – ${promo.activeTimeEnd}',
                        ),
                      if (promo.maxTotalRedemptions != null)
                        _DetailTile(
                          icon: Icons.group_rounded,
                          iconColor: AppTheme.successColor,
                          label: 'Remaining',
                          value:
                              '${promo.maxTotalRedemptions! - promo.currentRedemptions} of ${promo.maxTotalRedemptions} left',
                        ),
                      _DetailTile(
                        icon: Icons.repeat_rounded,
                        iconColor: AppTheme.warningColor,
                        label: 'Per person',
                        value: '${promo.maxPerUser} claim(s)',
                        isLast: true,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 240.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, delay: 240.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // ── Terms ─────────────────────────────────────────────────
                Text(
                  'Terms & Conditions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.dividerColor, width: 1),
                  ),
                  child: Column(
                    children: const [
                      _TermRow('Valid for dine-in only'),
                      _TermRow('Cannot be combined with other offers'),
                      _TermRow('Subject to availability'),
                      _TermRow('QR code expires 30 min after claiming'),
                      _TermRow('One redemption per visit'),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient hero fallback ────────────────────────────────────────────────────
class _GradientHero extends StatelessWidget {
  final Color color;
  const _GradientHero({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.6)],
        ),
      ),
      child: Center(
        child: Icon(Icons.storefront_rounded,
            size: 80, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }
}

// ── Detail tile ───────────────────────────────────────────────────────────────
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _DetailTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: AppTheme.dividerColor,
          ),
      ],
    );
  }
}

// ── Term row ──────────────────────────────────────────────────────────────────
class _TermRow extends StatelessWidget {
  final String text;
  const _TermRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Claim bottom bar ──────────────────────────────────────────────────────────
class _ClaimBar extends StatelessWidget {
  final bool isClaiming;
  final VoidCallback onClaim;

  const _ClaimBar({required this.isClaiming, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppTheme.navShadow,
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isClaiming ? null : AppTheme.accentGradient,
              color: isClaiming ? AppTheme.accentColor.withOpacity(0.4) : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isClaiming
                  ? []
                  : [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed: isClaiming ? null : onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: isClaiming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code_rounded,
                      color: Colors.white, size: 22),
              label: Text(
                isClaiming ? 'Claiming...' : 'Claim This Offer',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
