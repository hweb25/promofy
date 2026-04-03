import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/promotion_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final nearbyPromos = ref.watch(nearbyPromotionsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${profile.valueOrNull?['full_name']?.split(' ').first ?? 'there'}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Discovering deals near you',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/consumer/profile'),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryColor.withOpacity( 0.1),
                          child: const Icon(Icons.person, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for deals, restaurants...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: AppTheme.textLight),
                        hintStyle: TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _CategoryChip(icon: Icons.restaurant, label: 'Restaurant', color: Colors.orange),
                  _CategoryChip(icon: Icons.local_bar, label: 'Bar', color: Colors.purple),
                  _CategoryChip(icon: Icons.coffee, label: 'Cafe', color: Colors.brown),
                  _CategoryChip(icon: Icons.delivery_dining, label: 'Food Truck', color: Colors.green),
                  _CategoryChip(icon: Icons.cake, label: 'Bakery', color: Colors.pink),
                ],
              ),
            ),
          ),

          // Section: Nearby deals
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Deals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/consumer/promotions'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),

          // Promotions list
          nearbyPromos.when(
            data: (promos) {
              if (promos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.location_searching, size: 64, color: AppTheme.textLight),
                        SizedBox(height: 16),
                        Text(
                          'No deals found nearby',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try expanding your search radius or check back later!',
                          style: TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
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
                      final promo = promos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PromotionCard(
                          promotion: promo,
                          onTap: () => context.push('/consumer/promotion/${promo.id}'),
                        ),
                      );
                    },
                    childCount: promos.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text('Error loading deals: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(nearbyPromotionsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CategoryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
