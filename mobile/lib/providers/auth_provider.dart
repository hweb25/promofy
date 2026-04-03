import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.auth.onAuthStateChange;
});

// Current user
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.auth.currentUser;
});

// User profile
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final authService = ref.read(authServiceProvider);
  return await authService.getProfile();
});

// User role
final userRoleProvider = Provider<String>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  return profile?['role'] ?? 'consumer';
});

// Is business owner
final isBusinessOwnerProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == 'business_owner';
});
