import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../providers/promotion_provider.dart';
import '../../models/promotion.dart';
import '../../widgets/promotion_card.dart';

enum _DealsFilter { all, nearby, expiringSoon, popular }

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  _DealsFilter _activeFilter = _DealsFilter.all;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(
            () => _activeFilter = _DealsFilter.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Promotion> _applyFilter(List<Promotion> promos) {
    switch (_activeFilter) {
      case _DealsFilter.all:
        return promos;
      case _DealsFilter.nearby:
        final sorted = [...promos]..sort((a, b) =>
            (a.distanceMeters ?? double.infinity)
                .compareTo(b.distanceMeters ?? double.infinity));
        return sorted;
      case _DealsFilter.expiringSoon:
        final now = DateTime.now();
        final expiring = promos.where((p) {
          final diff = p.endsAt.difference(now);
          return diff.isNegative == false && diff.inHours < 24;
        }).toList()
          ..sort((a, b) => a.endsAt.compareTo(b.endsAt));
        return expiring;
      case _DealsFilter.popular:
        final sorted = [...promos]..sort(
            (a, b) => b.currentRedemptions.compareTo(a.currentRedemptions));
        return sorted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearbyPromos = ref.watch(nearbyPromotionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          // ── Header ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'All Deals',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: AppTheme.textSecondary, size: 18),
                ),
                onPressed: () => _showFilterSheet(context),
              ),
              const SizedBox(width: 8),
            ],

            // Search bar in appbar
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search deals...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.textLight,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppTheme.textLight, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 0, vertical: 12),
                          filled: false,
                        ),
                      ),
                    ),
                  ),

                  // Filter tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      _FilterTab(icon: Icons.grid_view_rounded, label: 'All'),
                      _FilterTab(icon: Icons.near_me_rounded, label: 'Nearby'),
                      _FilterTab(icon: Icons.timer_rounded, label: 'Expiring'),
                      _FilterTab(icon: Icons.trending_up_rounded, label: 'Popular'),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
        body: nearbyPromos.when(
          data: (promos) {
            final filtered = _applyFilter(promos);

            if (filtered.isEmpty) {
              return _EmptyState(filter: _activeFilter);
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(nearbyPromotionsProvider),
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final promo = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PromotionCard(
                      promotion: promo,
                      onTap: () =>
                          context.push('/consumer/promotion/${promo.id}'),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 350.ms,
                        )
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          delay: Duration(milliseconds: 50 * index),
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        ),
                  );
                },
              ),
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE8E4F7),
                highlightColor: Colors.white,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 52, color: AppTheme.textLight),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load deals',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(nearbyPromotionsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(),
    );
  }
}

// ── Filter tab widget ─────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FilterTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final _DealsFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    String message;
    String sub;
    IconData icon;

    switch (filter) {
      case _DealsFilter.expiringSoon:
        icon = Icons.timer_off_rounded;
        message = 'No expiring deals';
        sub = 'There are no deals expiring in the next 24 hours.';
        break;
      case _DealsFilter.nearby:
        icon = Icons.location_off_rounded;
        message = 'No deals nearby';
        sub = 'Try moving to a different location or expand your radius.';
        break;
      default:
        icon = Icons.local_offer_outlined;
        message = 'No deals available';
        sub = 'Check back later for new promotions in your area!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String _category = 'All';
  String _distance = '2km';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Text('Filter Deals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _category = 'All';
                      _distance = '2km';
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text('Category',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Restaurant', 'Bar', 'Cafe', 'Food Truck', 'Bakery']
                  .map((cat) {
                final isSelected = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            Text('Distance',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['500m', '1km', '2km', '5km', '10km'].map((d) {
                final isSelected = d == _distance;
                return GestureDetector(
                  onTap: () => setState(() => _distance = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      d,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.floatingShadow,
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
