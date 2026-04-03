import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/business_service.dart';
import '../models/business.dart';

final businessServiceProvider = Provider<BusinessService>((ref) => BusinessService());

// My business (for business owners)
final myBusinessProvider = FutureProvider<Business?>((ref) async {
  final service = ref.read(businessServiceProvider);
  return await service.getMyBusiness();
});

// Business analytics
final businessAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, businessId) async {
  final service = ref.read(businessServiceProvider);
  return await service.getAnalytics(businessId);
});
