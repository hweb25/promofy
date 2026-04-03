import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme.dart';
import '../../providers/promotion_provider.dart';
import '../../models/promotion.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Promotion? _selectedPromotion;

  @override
  Widget build(BuildContext context) {
    final nearbyPromos = ref.watch(nearbyPromotionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deals Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          nearbyPromos.when(
            data: (promos) {
              final markers = promos
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
                        onTap: () {
                          setState(() { _selectedPromotion = p; });
                        },
                      ))
                  .toSet();

              // Add geofence circles
              final circles = promos
                  .where((p) => p.latitude != null && p.longitude != null)
                  .map((p) => Circle(
                        circleId: CircleId(p.id),
                        center: LatLng(p.latitude!, p.longitude!),
                        radius: (p.geofenceRadius ?? 200).toDouble(),
                        fillColor: AppTheme.primaryColor.withOpacity(0.1),
                        strokeColor: AppTheme.primaryColor.withOpacity(0.3),
                        strokeWidth: 2,
                      ))
                  .toSet();

              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(4.7110, -74.0721), // Bogota default
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
                onTap: (_) {
                  setState(() { _selectedPromotion = null; });
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading map: $e')),
          ),

          // Selected promotion card
          if (_selectedPromotion != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _PromotionMapCard(
                promotion: _selectedPromotion!,
                onTap: () => context.push('/consumer/promotion/${_selectedPromotion!.id}'),
                onDismiss: () => setState(() { _selectedPromotion = null; }),
              ),
            ),

          // Filter chips
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: true),
                  _FilterChip(label: 'Restaurants', selected: false),
                  _FilterChip(label: 'Bars', selected: false),
                  _FilterChip(label: 'Cafes', selected: false),
                ],
              ),
            ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  promotion.discountLabel,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    promotion.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.businessName ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.formattedDistance,
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? AppTheme.primaryColor : Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
    );
  }
}
