import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
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
    final name =
        profile.valueOrNull?['full_name']?.toString().split(' ').first ?? 'there';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(nearbyPromotionsProvider),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // ── Clean white header: location + search + FAB ──────────────────
          SliverToBoxAdapter(child: _Header(name: name)),

          // ── Promo banner ─────────────────────────────────────────────────
          const SliverToBoxAdapter(child: _PromoBanner()),

          // ── Category grid (4 columns) ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
                children: const [
                  _CategoryIcon('Restaurant', Icons.restaurant_rounded, Color(0xFFFF6B35)),
                  _CategoryIcon('Pizza', Icons.local_pizza_rounded, Color(0xFFDC2626)),
                  _CategoryIcon('Burgers', Icons.lunch_dining_rounded, Color(0xFFD97706)),
                  _CategoryIcon('Sushi', Icons.set_meal_rounded, Color(0xFF0284C7)),
                  _CategoryIcon('Cafe', Icons.coffee_rounded, Color(0xFF92400E)),
                  _CategoryIcon('Bakery', Icons.cake_rounded, Color(0xFFDB2777)),
                  _CategoryIcon('Bar', Icons.local_bar_rounded, Color(0xFF7C3AED)),
                  _CategoryIcon('More', Icons.grid_view_rounded, AppTheme.primaryColor),
                ],
              ),
            ),
          ),

          // ── Near you ─────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: _SectionHeader(title: 'Near you')),
          SliverToBoxAdapter(
            child: nearbyPromos.when(
              data: (promos) {
                if (promos.isEmpty) return const SizedBox.shrink();
                final list = promos.take(6).toList();
                return SizedBox(
                  height: 232,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final promo = list[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: SizedBox(
                          width: 210,
                          child: PromotionCard(
                            promotion: promo,
                            compact: true,
                            onTap: () =>
                                context.push('/consumer/promotion/${promo.id}'),
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

          // ── Popular now ──────────────────────────────────────────────────
          const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Popular now', hot: true)),
          nearbyPromos.when(
            data: (promos) {
              if (promos.isEmpty) {
                return SliverToBoxAdapter(child: _EmptyDeals(ref: ref));
              }
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
                          onTap: () =>
                              context.push('/consumer/promotion/${promo.id}'),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 60 * index),
                              duration: 400.ms)
                          .slideY(
                              begin: 0.15,
                              end: 0,
                              delay: Duration(milliseconds: 60 * index),
                              duration: 400.ms,
                              curve: Curves.easeOut);
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
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
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
                    Text('Could not load deals',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(nearbyPromotionsProvider),
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

// ── Clean header (location + search + FAB) ────────────────────────────────────
class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: AppTheme.surfaceColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR AREA',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 17, color: AppTheme.primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              'Deals near you',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: AppTheme.textPrimary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // notification bell
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
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          color: AppTheme.textPrimary, size: 21),
                    ),
                  ),
                  // avatar → profile
                  GestureDetector(
                    onTap: () => context.go('/consumer/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.bannerGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _SearchBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search pill + FAB ─────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/consumer/promotions'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 14),
                  Icon(Icons.search_rounded,
                      color: AppTheme.textLight, size: 21),
                  SizedBox(width: 10),
                  Text(
                    'Search deals, places…',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppTheme.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push('/consumer/promotions'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 21),
          ),
        ),
      ],
    );
  }
}

// ── Promo banner ──────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: PressableScale(
        onTap: () => context.push('/consumer/promotions'),
        child: Container(
          height: 116,
          decoration: BoxDecoration(
            gradient: AppTheme.bannerGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -18,
                child: Text(
                  '🎉',
                  style: TextStyle(
                    fontSize: 92,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Up to 50% OFF',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'this week at top local spots',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Explore deals',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.violetAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool hot;
  const _SectionHeader({required this.title, this.hot = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (hot) ...[
                const SizedBox(width: 6),
                const Icon(Icons.local_fire_department_rounded,
                    size: 18, color: AppTheme.accentColor),
              ],
            ],
          ),
          GestureDetector(
            onTap: () => context.go('/consumer/promotions'),
            child: const Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 27),
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

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyDeals extends StatelessWidget {
  final WidgetRef ref;
  const _EmptyDeals({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
          Text('No deals nearby yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Pull down to refresh or try widening your search radius.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => ref.invalidate(nearbyPromotionsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer loaders ─────────────────────────────────────────────────────────────
class _HorizontalShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFEAE9F0),
            highlightColor: Colors.white,
            child: Container(
              width: 210,
              height: 232,
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
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEAE9F0),
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
