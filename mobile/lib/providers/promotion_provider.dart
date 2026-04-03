import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/promotion_service.dart';
import '../services/location_service.dart';
import '../models/promotion.dart';
import '../models/redemption.dart';

final promotionServiceProvider = Provider<PromotionService>((ref) => PromotionService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Nearby promotions
final nearbyPromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  final promotionService = ref.read(promotionServiceProvider);

  final position = await locationService.getCurrentPosition();
  if (position == null) return [];

  return await promotionService.getNearbyPromotions(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusMeters: 5000,
  );
});

// Single promotion
final promotionDetailProvider = FutureProvider.family<Promotion, String>((ref, id) async {
  final service = ref.read(promotionServiceProvider);
  return await service.getPromotion(id);
});

// My redemptions
final myRedemptionsProvider = FutureProvider<List<Redemption>>((ref) async {
  final service = ref.read(promotionServiceProvider);
  return await service.getMyRedemptions();
});

// Business promotions
final businessPromotionsProvider = FutureProvider.family<List<Promotion>, String>((ref, businessId) async {
  final service = ref.read(promotionServiceProvider);
  return await service.getBusinessPromotions(businessId);
});
