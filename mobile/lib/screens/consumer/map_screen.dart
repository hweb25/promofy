import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/promotion_provider.dart';
import '../../models/promotion.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Promotion? _selectedPromotion;
  String _selectedCategory = 'All';
  late DraggableScrollableController _sheetController;

  static const _categories = ['All', 'Restaurant', 'Bar', 'Cafe', 'Food Truck', 'Bakery'];

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyPromos = ref.watch(nearbyPromotionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // ── Google Map ───────────────────────────────────────────────────
          nearbyPromos.when(
            data: (promos) {
              final filtered = _selectedCategory == 'All'
                  ? promos
                  : promos.where((p) =>
                      (p.businessCategory ?? '')
                          .toLowerCase()
                          .contains(_selectedCategory.toLowerCase()))
                      .toList();

              final markers = filtered
                  .where((p) => p.latitude != null && p.longitude != null)
                  .map((p) => Marker(
                        markerId: MarkerId(p.id),
                        position: LatLng(p.latitude!, p.longitude!),
                        infoWindow: InfoWindow(
                          title: p.businessName ?? p.title,
                          snippet: p.discountLabel,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet,
                        ),
                        onTap: () => setState(() => _selectedPromotion = p),
                      ))
                  .toSet();

              final circles = filtered
                  .where((p) => p.latitude != null && p.longitude != null)
                  .map((p) => Circle(
                        circleId: CircleId(p.id),
                        center: LatLng(p.latitude!, p.longitude!),
                        radius: (p.geofenceRadius ?? 200).toDouble(),
                        fillColor: AppTheme.primaryColor.withOpacity(0.08),
                        strokeColor: AppTheme.primaryColor.withOpacity(0.25),
                        strokeWidth: 2,
                      ))
                  .toSet();

              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(4.7110, -74.0721),
                  zoom: 14,
                ),
                markers: markers,
                circles: circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  _goToCurrentLocation();
                },
                onTap: (_) => setState(() => _selectedPromotion = null),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error loading map: $e',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ),

          // ── Top bar: search + category chips ────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      // Search pill
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 14),
                              Icon(Icons.search_rounded,
                                  color: AppTheme.textLight, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Search on map...',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category filter chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Selected promotion popup ─────────────────────────────────────
          if (_selectedPromotion != null)
            Positioned(
              bottom: 260,
              left: 16,
              right: 16,
              child: _PromotionMapCard(
                promotion: _selectedPromotion!,
                onTap: () => context.push('/consumer/promotion/${_selectedPromotion!.id}'),
                onDismiss: () => setState(() => _selectedPromotion = null),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.3, end: 0, duration: 300.ms),
            ),

          // ── FAB: center on me ────────────────────────────────────────────
          Positioned(
            bottom: 240,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'my_location',
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.my_location_rounded, size: 22),
            ),
          ),

          // ── Bottom sheet: nearby deals list ──────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.65,
            snap: true,
            snapSizes: const [0.12, 0.28, 0.65],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            'Nearby Deals',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          nearbyPromos.when(
                            data: (p) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${p.length} deals',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: nearbyPromos.when(
                        data: (promos) => ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: promos.length,
                          itemBuilder: (context, index) {
                            final promo = promos[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BottomSheetPromoTile(
                                promotion: promo,
                                onTap: () => context.push(
                                    '/consumer/promotion/${promo.id}'),
                                onMapTap: () {
                                  if (promo.latitude != null &&
                                      promo.longitude != null) {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(promo.latitude!, promo.longitude!),
                                        16,
                                      ),
                                    );
                                    setState(() => _selectedPromotion = promo);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(fontFamily: 'Poppins')),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    }
  }
}

// ── Promotion map popup card ──────────────────────────────────────────────────
class _PromotionMapCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _PromotionMapCard({
    required this.promotion,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Discount badge
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  promotion.discountLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    promotion.businessName ?? '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (promotion.distanceMeters != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppTheme.primaryColor),
                        const SizedBox(width: 3),
                        Text(
                          promotion.formattedDistance,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Dismiss
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onDismiss,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet promo tile ───────────────────────────────────────────────────
class _BottomSheetPromoTile extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTap;
  final VoidCallback onMapTap;

  const _BottomSheetPromoTile({
    required this.promotion,
    required this.onTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(promotion.businessCategory ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                AppTheme.categoryIcon(promotion.businessCategory ?? ''),
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    promotion.businessName ?? 'Local Business',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Discount + map
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promotion.discountLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (promotion.distanceMeters != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    promotion.formattedDistance,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
