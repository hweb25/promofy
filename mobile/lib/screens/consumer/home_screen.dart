import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/promotion.dart';
import '../../providers/auth_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/promotion_card.dart';
import '../../widgets/effects.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final nearbyPromos = ref.watch(nearbyPromotionsProvider);
    final firstName =
        profile.valueOrNull?['full_name']?.toString().split(' ').first ?? 'there';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(nearbyPromotionsProvider),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // ── Gradient Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HomeHeader(firstName: firstName),
          ),

          // ── Search + Filter Row ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _SearchBar(),
            ),
          ),

          // ── Featured Deal (the screen's focal point) ─────────────────────
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final promos = nearbyPromos.valueOrNull;
                if (promos == null || promos.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _FeaturedDeal(
                    promotion: promos.first,
                    onTap: () => context
                        .push('/consumer/promotion/${promos.first.id}'),
                  ),
                );
              },
            ),
          ),

          // ── Category Icons ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ),
                // 4-column category grid (Rappi-style discovery layout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.78,
                    children: const [
                      _CategoryIcon('Restaurant', Icons.restaurant_rounded, Color(0xFFFF6B35)),
                      _CategoryIcon('Bar', Icons.local_bar_rounded, Color(0xFF7C3AED)),
                      _CategoryIcon('Cafe', Icons.coffee_rounded, Color(0xFF92400E)),
                      _CategoryIcon('Food Truck', Icons.delivery_dining_rounded, Color(0xFF059669)),
                      _CategoryIcon('Bakery', Icons.cake_rounded, Color(0xFFDB2777)),
                      _CategoryIcon('Pizza', Icons.local_pizza_rounded, Color(0xFFDC2626)),
                      _CategoryIcon('Sushi', Icons.set_meal_rounded, Color(0xFF0284C7)),
                      _CategoryIcon('Fast Food', Icons.fastfood_rounded, Color(0xFFD97706)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Near You ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Near You',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 20),
                  ),
                  TextButton(
                    onPressed: () => context.go('/consumer/promotions'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal scroll near you
          SliverToBoxAdapter(
            child: nearbyPromos.when(
              data: (promos) {
                if (promos.isEmpty) return const SizedBox.shrink();
                // Skip the deal already shown in the Featured hero so it isn't
                // duplicated immediately below it.
                final nearList =
                    (promos.length > 1 ? promos.skip(1) : promos)
                        .take(6)
                        .toList();
                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: nearList.length,
                    itemBuilder: (context, index) {
                      final promo = nearList[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: SizedBox(
                          width: 200,
                          child: PromotionCard(
                            promotion: promo,
                            compact: true,
                            onTap: () => context.push(
                                '/consumer/promotion/${promo.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => _HorizontalShimmer(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Popular Deals ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Deals',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppTheme.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Hot',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vertical list of popular deals
          nearbyPromos.when(
            data: (promos) {
              if (promos.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyDeals(),
                );
              }
              // Honest "Popular" ordering: most-claimed first (the label implied
              // a ranking the raw nearby list didn't actually have).
              final popular = [...promos]
                ..sort((a, b) =>
                    b.currentRedemptions.compareTo(a.currentRedemptions));
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final promo = popular[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PromotionCard(
                          promotion: promo,
                          onTap: () => context.push(
                              '/consumer/promotion/${promo.id}'),
                        ),
                      )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 60 * index),
                            duration: 400.ms,
                          )
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            delay: Duration(milliseconds: 60 * index),
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          );
                    },
                    childCount: popular.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CardShimmer(),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 52, color: AppTheme.textLight),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load deals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(nearbyPromotionsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HomeHeader extends ConsumerWidget {
  final String firstName;
  const _HomeHeader({required this.firstName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.78),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$firstName!',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification bell
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "You're all caught up — no new notifications",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ),

                  // Avatar
                  GestureDetector(
                    onTap: () => context.go('/consumer/profile'),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppTheme.primaryColor, size: 24),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    'Discovering deals near you',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: TextField(
        readOnly: true,
        onTap: () => context.push('/consumer/promotions'),
        decoration: InputDecoration(
          hintText: 'Search deals, restaurants...',
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.textLight,
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textLight, size: 22),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: false,
        ),
      ),
    );
  }
}

// ── Category Icon ─────────────────────────────────────────────────────────────
class _CategoryIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryIcon(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => context.push('/consumer/promotions'),
      pressedScale: 0.92,
      child: Semantics(
        button: true,
        label: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyDeals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_searching_rounded,
                size: 38, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'No deals nearby yet',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh or try expanding\nyour search radius.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Loading ───────────────────────────────────────────────────────────
class _HorizontalShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE8E4F7),
            highlightColor: Colors.white,
            child: Container(
              width: 200,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E4F7),
      highlightColor: Colors.white,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

// ── Featured Deal banner (top nearby promo) ───────────────────────────────────
class _FeaturedDeal extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTap;
  const _FeaturedDeal({required this.promotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(promotion.businessCategory ?? '');
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 156,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (promotion.imageUrl != null)
              CachedNetworkImage(
                imageUrl: promotion.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _gradient(color),
              )
            else
              _gradient(color),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.15),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '⭐ Featured',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          promotion.discountLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded,
                              size: 13, color: Colors.white.withOpacity(0.85)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              promotion.businessName ?? 'Local business',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (promotion.distanceMeters != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.location_on_rounded,
                                size: 13,
                                color: Colors.white.withOpacity(0.85)),
                            const SizedBox(width: 2),
                            Text(
                              promotion.formattedDistance,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (promotion.isLowStock ||
                          promotion.currentRedemptions > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              promotion.isLowStock
                                  ? Icons.local_fire_department_rounded
                                  : Icons.people_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              promotion.isLowStock
                                  ? 'Only ${promotion.remainingRedemptions} left'
                                  : '${promotion.currentRedemptions} claimed',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _gradient(Color color) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.6)],
          ),
        ),
      );
}
