import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/promotion_card.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyPromos = ref.watch(nearbyPromotionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(nearbyPromotionsProvider),
        child: nearbyPromos.when(
          data: (promos) {
            if (promos.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined, size: 64, color: AppTheme.textLight),
                    SizedBox(height: 16),
                    Text('No deals available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('Check back later for new promotions!', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: promos.length,
              itemBuilder: (context, index) {
                final promo = promos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PromotionCard(
                    promotion: promo,
                    onTap: () => context.push('/consumer/promotion/${promo.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Deals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'Restaurant', 'Bar', 'Cafe', 'Food Truck', 'Bakery']
                  .map((c) => FilterChip(label: Text(c), selected: c == 'All', onSelected: (_) {}))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text('Distance', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['500m', '1km', '2km', '5km']
                  .map((d) => ChoiceChip(label: Text(d), selected: d == '2km', onSelected: (_) {}))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
