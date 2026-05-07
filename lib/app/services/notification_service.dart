import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications importantes',
    description: 'Notifications de GrandPublic',
    importance: Importance.high,
    playSound: true,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveFcmToken();
    _listenToTokenRefresh();
    _listenForeground();
    _listenNotificationTap();
    await _checkInitialMessage();
  }

  // ── Permission ────────────────────────────────────────────────────────────
  static Future<void> _requestPermission() async {
    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    debugPrint('Permission: ${settings.authorizationStatus}');
  }

  // ── Local Notifications setup ─────────────────────────────────────────────
  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // ← paramètre nommé 'settings' obligatoire
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notif tapped: ${response.payload}');
        _navigateFromPayload(response.payload);
      },
    );

    // ← pas de await sur resolvePlatformSpecificImplementation
    _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  // ── FCM Token ─────────────────────────────────────────────────────────────
  static Future<void> _saveFcmToken() async {
    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      GetStorage().write('fcm_token', token);
      await _sendTokenToBackend(token);
    }
  }

  static void _listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      debugPrint('FCM Token refreshed: $token');
      GetStorage().write('fcm_token', token);
      await _sendTokenToBackend(token);
    });
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      if (useMock) return;
      final String? authToken = GetStorage().read<String>('token');
      if (authToken == null) return;
      await RequestService().post(
        '/users/update-profile',
        data: {'fcm_token': token, 'device': 'mobile'},
      );
      debugPrint('FCM token envoyé au backend');
    } catch (e) {
      debugPrint('Erreur envoi FCM token: $e');
    }
  }

  // ── Foreground messages ───────────────────────────────────────────────────
  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground: ${message.notification?.title}');
      final RemoteNotification? notification = message.notification;
      if (notification == null) return;

      // ← paramètres nommés pour show()
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
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
        payload: jsonEncode(message.data),
      );
    });
  }

  // ── Tap notification (background) ─────────────────────────────────────────
  static void _listenNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.data}');
      _navigateFromData(message.data);
    });
  }

  // ── App ouverte depuis notification (terminée) ────────────────────────────
  static Future<void> _checkInitialMessage() async {
    final RemoteMessage? message = await FirebaseMessaging.instance
        .getInitialMessage();
    if (message != null) {
      Future.delayed(const Duration(seconds: 1), () {
        _navigateFromData(message.data);
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  static void _navigateFromData(Map<String, dynamic> data) {
    final String? route = data['route'];
    if (route == null || route.isEmpty) return;
    Get.toNamed(route, arguments: data);
  }

  static void _navigateFromPayload(String? payload) {
    if (payload == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigateFromData(data);
    } catch (_) {
      Get.toNamed(payload);
    }
  }

  // ── Utilitaires publics ───────────────────────────────────────────────────
  static String? getFcmToken() => GetStorage().read<String>('fcm_token');

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? route,
    int id = 0,
  }) async {
    // ← paramètres nommés pour show()
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: route,
    );
  }
}
