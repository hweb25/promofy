import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/promotion_provider.dart';

class PromotionDetailScreen extends ConsumerStatefulWidget {
  final String promotionId;
  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  ConsumerState<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends ConsumerState<PromotionDetailScreen> {
  bool _isClaiming = false;

  Future<void> _claimOffer() async {
    setState(() => _isClaiming = true);
    try {
      final service = ref.read(promotionServiceProvider);
      final result = await service.claimPromotion(widget.promotionId);

      if (result['success'] == true && mounted) {
        context.push('/consumer/redemption/${result['redemption_id']}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to claim offer')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final promoAsync = ref.watch(promotionDetailProvider(widget.promotionId));

    return Scaffold(
      body: promoAsync.when(
        data: (promo) => CustomScrollView(
          slivers: [
            // App Bar with image
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            promo.discountLabel,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Business
                    Text(
                      promo.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.store, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          promo.businessName ?? 'Local Business',
                          style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        if (promo.distanceMeters != null) ...[
                          const Icon(Icons.location_on, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            promo.formattedDistance,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      promo.description,
                      style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Details cards
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Valid until',
                      value: DateFormat('MMM dd, yyyy - HH:mm').format(promo.endsAt),
                    ),
                    const SizedBox(height: 12),
                    if (promo.activeTimeStart != null && promo.activeTimeEnd != null)
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Active hours',
                        value: '${promo.activeTimeStart} - ${promo.activeTimeEnd}',
                      ),
                    const SizedBox(height: 12),
                    if (promo.maxTotalRedemptions != null)
                      _DetailRow(
                        icon: Icons.people,
                        label: 'Remaining',
                        value: '${promo.maxTotalRedemptions! - promo.currentRedemptions} left',
                      ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.repeat,
                      label: 'Per person',
                      value: '${promo.maxPerUser} claim(s)',
                    ),

                    const SizedBox(height: 40),

                    // Terms
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text(
                            '- Valid for dine-in only\n- Cannot be combined with other offers\n- Subject to availability\n- QR code expires 30 min after claiming',
                            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),

      // Claim button
      bottomSheet: promoAsync.valueOrNull != null
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isClaiming ? null : _claimOffer,
                    icon: _isClaiming
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.qr_code),
                    label: Text(_isClaiming ? 'Claiming...' : 'Claim This Offer'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
