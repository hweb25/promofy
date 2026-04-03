import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/business_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(myBusinessProvider);
    final currentTier = business.valueOrNull?.subscriptionTier ?? 'free';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Your Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Scale your reach and attract more customers',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Free Plan
            _PlanCard(
              tier: 'free',
              name: 'Basic',
              price: 'Free',
              priceSubtitle: 'forever',
              radius: '50 - 100m',
              features: [
                '1 Active Promotion',
                'Basic Analytics',
                'QR Code Redemption',
                '50-100m Geofence Radius',
              ],
              isCurrentPlan: currentTier == 'free',
              color: AppTheme.textSecondary,
              onSelect: () {},
            ),
            const SizedBox(height: 16),

            // Premium Plan
            _PlanCard(
              tier: 'premium',
              name: 'Premium',
              price: '\$49 - \$79',
              priceSubtitle: '/month',
              radius: '500m - 1km',
              features: [
                'Up to 3 Active Promotions',
                'Advanced Analytics & ROI',
                'QR Code Redemption',
                '500m - 1km Geofence Radius',
                'Priority Support',
              ],
              isCurrentPlan: currentTier == 'premium',
              isPopular: true,
              color: AppTheme.primaryColor,
              onSelect: () => _showUpgradeDialog(context, 'Premium'),
            ),
            const SizedBox(height: 16),

            // Gold Plan
            _PlanCard(
              tier: 'gold',
              name: 'Gold',
              price: '\$129 - \$199',
              priceSubtitle: '/month',
              radius: '2km - 5km',
              features: [
                'Unlimited Promotions',
                'Full Analytics Suite',
                'QR Code Redemption',
                '2km - 5km (City-wide) Radius',
                'Priority Listing in Feed',
                'Dedicated Account Manager',
              ],
              isCurrentPlan: currentTier == 'gold',
              color: const Color(0xFFFFD700),
              onSelect: () => _showUpgradeDialog(context, 'Gold'),
            ),
            const SizedBox(height: 32),

            // FAQ
            const Text('Frequently Asked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _FaqItem(
              question: 'Can I switch plans anytime?',
              answer: 'Yes! You can upgrade or downgrade at any time. Changes take effect immediately.',
            ),
            _FaqItem(
              question: 'How does billing work?',
              answer: 'You\'re billed monthly via Stripe. Cancel anytime with no hidden fees.',
            ),
            _FaqItem(
              question: 'What is the geofence radius?',
              answer: 'It determines how far from your business customers will receive notifications. Larger radius = more reach.',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, String plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Upgrade to $plan'),
        content: Text('You\'ll be redirected to Stripe to complete payment for the $plan plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Redirect to Stripe checkout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stripe checkout coming soon!')),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String tier, name, price, priceSubtitle, radius;
  final List<String> features;
  final bool isCurrentPlan, isPopular;
  final Color color;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.tier,
    required this.name,
    required this.price,
    required this.priceSubtitle,
    required this.radius,
    required this.features,
    required this.isCurrentPlan,
    this.isPopular = false,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrentPlan ? color : AppTheme.dividerColor,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]
            : null,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    const Spacer(),
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('CURRENT', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(priceSubtitle, style: const TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Geofence: $radius', style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: color),
                      const SizedBox(width: 12),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                if (!isCurrentPlan)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: Text(tier == 'free' ? 'Downgrade' : 'Upgrade to $name'),
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

class _FaqItem extends StatefulWidget {
  final String question, answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w600))),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(widget.answer, style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
