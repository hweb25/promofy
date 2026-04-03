import 'dart:typed_data';
import 'supabase_service.dart';
import '../models/business.dart';

class BusinessService {
  final _client = SupabaseService.client;

  // Get business by owner
  Future<Business?> getMyBusiness() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .single();

      return Business.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create business
  Future<Business> createBusiness(Map<String, dynamic> data) async {
    // Build PostGIS point from lat/lng
    final lat = data.remove('latitude');
    final lng = data.remove('longitude');
    data['location'] = 'POINT($lng $lat)';
    data['owner_id'] = SupabaseService.currentUserId;

    final response = await _client
        .from('businesses')
        .insert(data)
        .select()
        .single();

    return Business.fromJson(response);
  }

  // Update business
  Future<void> updateBusiness(String id, Map<String, dynamic> data) async {
    if (data.containsKey('latitude') && data.containsKey('longitude')) {
      final lat = data.remove('latitude');
      final lng = data.remove('longitude');
      data['location'] = 'POINT($lng $lat)';
    }

    await _client.from('businesses').update(data).eq('id', id);
  }

  // Get business analytics
  Future<Map<String, dynamic>> getAnalytics(String businessId) async {
    final response = await _client
        .from('business_analytics_summary')
        .select()
        .eq('business_id', businessId)
        .single();

    return response;
  }

  // Get analytics for date range
  Future<List<Map<String, dynamic>>> getAnalyticsEvents({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    String? eventType,
  }) async {
    var query = _client
        .from('analytics_events')
        .select()
        .eq('business_id', businessId)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    if (eventType != null) {
      query = query.eq('event_type', eventType);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Upload business logo
  Future<String> uploadLogo(String businessId, List<int> bytes, String fileName) async {
    final path = 'businesses/$businessId/logo_$fileName';
    await _client.storage.from('business-assets').uploadBinary(path, Uint8List.fromList(bytes));
    return _client.storage.from('business-assets').getPublicUrl(path);
  }
}
