import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class ProximityService {
  static final ProximityService _instance = ProximityService._internal();
  factory ProximityService() => _instance;
  ProximityService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final NotificationService _notificationService = NotificationService();
  final Set<String> _notifiedPromotions = {};
  bool _isRunning = false;

  /// Start monitoring location and checking for nearby promotions
  Future<void> startMonitoring() async {
    if (_isRunning) return;

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('ProximityService: Location permission denied');
        return;
      }

      // Load previously notified promotions (don't spam the same ones)
      await _loadNotifiedPromotions();

      _isRunning = true;
      debugPrint('ProximityService: Started monitoring');

      // Check immediately on start
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _checkNearbyPromotions(position);
      } catch (e) {
        debugPrint('ProximityService: Initial check error: $e');
      }

      // Then listen for location changes (every 100m movement)
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100, // trigger every 100 meters
        ),
      ).listen(
        (Position position) {
          _checkNearbyPromotions(position);
        },
        onError: (e) {
          debugPrint('ProximityService: Stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('ProximityService: Start error: $e');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isRunning = false;
    debugPrint('ProximityService: Stopped monitoring');
  }

  /// Check for nearby promotions and send notifications
  Future<void> _checkNearbyPromotions(Position position) async {
    try {
      debugPrint(
          'ProximityService: Checking at ${position.latitude}, ${position.longitude}');

      // Call the Supabase RPC function
      final response =
          await SupabaseService.client.rpc('get_nearby_promotions', params: {
        'user_lat': position.latitude,
        'user_lng': position.longitude,
        'radius_meters': 15000, // 15km radius
      });

      final promos = response as List;
      debugPrint('ProximityService: Found ${promos.length} nearby promotions');

      for (final promo in promos) {
        final promoId = promo['promotion_id'] as String;
        final distance = (promo['distance_meters'] as num).toDouble();
        final geofenceRadius = (promo['geofence_radius'] as num?)?.toDouble() ?? 15000;

        // Only notify if within geofence radius and not already notified
        if (distance <= geofenceRadius && !_notifiedPromotions.contains(promoId)) {
          // Send local notification
          await _notificationService.showPromotionNotification(
            title: '🎉 ${promo['business_name']} — Deal Nearby!',
            body:
                '${promo['title']} — ${_formatDistance(distance)} away! Tap to claim.',
            promotionId: promoId,
          );

          // Mark as notified
          _notifiedPromotions.add(promoId);
          await _saveNotifiedPromotions();

          debugPrint(
              'ProximityService: Notified for "${ promo['title']}" at ${distance.round()}m');
        }
      }
    } catch (e) {
      debugPrint('ProximityService: Check error: $e');
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  /// Persist notified promotions so we don't re-notify after app restart
  Future<void> _loadNotifiedPromotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('notified_promotions') ?? [];
      _notifiedPromotions.addAll(list);

      // Clear old entries (reset daily)
      final lastReset = prefs.getString('notified_reset_date');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (lastReset != today) {
        _notifiedPromotions.clear();
        await prefs.setStringList('notified_promotions', []);
        await prefs.setString('notified_reset_date', today);
      }
    } catch (e) {
      debugPrint('ProximityService: Load prefs error: $e');
    }
  }

  Future<void> _saveNotifiedPromotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'notified_promotions', _notifiedPromotions.toList());
    } catch (e) {
      debugPrint('ProximityService: Save prefs error: $e');
    }
  }

  /// Reset notifications (for testing — allows re-notification)
  Future<void> resetNotifications() async {
    _notifiedPromotions.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notified_promotions', []);
  }
}
