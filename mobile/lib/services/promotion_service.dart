import 'supabase_service.dart';
import '../models/promotion.dart';
import '../models/redemption.dart';

class PromotionService {
  final _client = SupabaseService.client;

  // Get nearby promotions using PostGIS function
  Future<List<Promotion>> getNearbyPromotions({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    final response = await _client.rpc('get_nearby_promotions', params: {
      'user_lat': latitude,
      'user_lng': longitude,
      'radius_meters': radiusMeters,
    });

    return (response as List)
        .map((json) => Promotion.fromJson(json))
        .toList();
  }

  // Get all promotions for a business
  Future<List<Promotion>> getBusinessPromotions(String businessId) async {
    final response = await _client
        .from('promotions')
        .select('*, businesses(name, logo_url, category)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final business = json['businesses'];
      return Promotion.fromJson({
        ...json,
        'business_name': business?['name'],
        'business_logo': business?['logo_url'],
        'business_category': business?['category'],
      });
    }).toList();
  }

  // Get single promotion
  Future<Promotion> getPromotion(String id) async {
    final response = await _client
        .from('active_promotions_view')
        .select()
        .eq('id', id)
        .single();

    return Promotion.fromJson(response);
  }

  // Create promotion (business)
  Future<Promotion> createPromotion(Map<String, dynamic> data) async {
    final response = await _client
        .from('promotions')
        .insert(data)
        .select()
        .single();

    return Promotion.fromJson(response);
  }

  // Update promotion
  Future<void> updatePromotion(String id, Map<String, dynamic> data) async {
    await _client.from('promotions').update(data).eq('id', id);
  }

  // Delete promotion
  Future<void> deletePromotion(String id) async {
    await _client.from('promotions').delete().eq('id', id);
  }

  // Claim a promotion (consumer)
  Future<Map<String, dynamic>> claimPromotion(String promotionId) async {
    final response = await _client.rpc('claim_promotion', params: {
      'p_consumer_id': SupabaseService.currentUserId,
      'p_promotion_id': promotionId,
    });

    return response as Map<String, dynamic>;
  }

  // Get consumer's redemptions
  Future<List<Redemption>> getMyRedemptions() async {
    final response = await _client
        .from('redemptions')
        .select()
        .eq('consumer_id', SupabaseService.currentUserId!)
        .order('claimed_at', ascending: false);

    return (response as List)
        .map((json) => Redemption.fromJson(json))
        .toList();
  }

  // Validate redemption (business scans QR)
  Future<Map<String, dynamic>> validateRedemption({
    required String code,
    required String businessId,
  }) async {
    final response = await _client.rpc('validate_redemption', params: {
      'p_redemption_code': code,
      'p_business_id': businessId,
      'p_validated_by': SupabaseService.currentUserId,
    });

    return response as Map<String, dynamic>;
  }
}
