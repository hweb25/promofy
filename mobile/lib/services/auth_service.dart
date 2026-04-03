import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final _auth = SupabaseService.auth;
  final _client = SupabaseService.client;

  // Email/Password Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'consumer',
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
    return response;
  }

  // Email/Password Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.promofy.app://login-callback',
    );
  }

  // Facebook Sign In
  Future<bool> signInWithFacebook() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.promofy.app://login-callback',
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  // Update profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await _client.from('profiles').update(data).eq('id', userId);
  }

  // Update push token
  Future<void> updatePushToken(String token, String platform) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await _client.from('profiles').update({
      'push_token': token,
      'device_platform': platform,
    }).eq('id', userId);
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // Auth state stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Current session
  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
}
