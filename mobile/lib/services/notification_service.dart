import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel (Android)
    const channel = AndroidNotificationChannel(
      'promofy_promotions',
      'Promotions',
      description: 'Nearby promotion notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get and save token
    final token = await _messaging.getToken();
    if (token != null) {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _authService.updatePushToken(token, platform);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      final platform = Platform.isIOS ? 'ios' : 'android';
      _authService.updatePushToken(token, platform);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'promofy_promotions',
          'Promotions',
          channelDescription: 'Nearby promotion notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['promotion_id'],
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to promotion detail - handled by router
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigate to promotion detail - handled by router
  }

  // Show local notification (for geofence triggers)
  Future<void> showPromotionNotification({
    required String title,
    required String body,
    String? promotionId,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'promofy_promotions',
          'Promotions',
          channelDescription: 'Nearby promotion notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6C5CE7),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: promotionId,
    );
  }
}

// Color is imported from dart:ui via flutter/material.dart
