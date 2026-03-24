import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:http/http.dart' as http;

class FCMService {
  // ══════════════════════════════════════════════════════════════════════════
  // CONFIG — remplace par ton projet
  // ══════════════════════════════════════════════════════════════════════════
  static const String _projectId = 'grand-public-f4fd5';
  static const String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  // Service Account JSON — depuis Firebase Console
  // → Paramètres du projet → Comptes de service → Générer une clé privée
  static const Map<String, dynamic> _serviceAccount = {
    "type": "service_account",
    "project_id": "grand-public-f4fd5",
    "private_key_id": "d0c14823b4556dd27728116d4b3d1d323cd6d56b",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDXgVXXdMPsFbWL\ncKDyt4KsLdBVQ2K/3uoexsnt2473pMy4kXT92nEGkRyB2jeLMkO6Sw8FnKKQ8BPR\nHx/kdkqDYNrfnHMALfduLXlAYfHKRWTjT+ilQfE0Qu40mSO4cYtNhra82paOARip\ncVx6x0FS0OWyvsK2c6hxMZGDj4n0IrkkQubtrfh9oeRo70oUZepeALJxPxGBlrjS\n5ueVEqwXK/zXnxMRttwKQaj9sN2VlvkkE3wGlItOOerXRymlVjx1fhJktvjdMx/r\nD7egNnuVKB0yZNV5PgZDE6j0qGuzo1Ycbgm3NvJpni4xcbIy2Yke4zOI0EsQtzaf\ndKm2tPZVAgMBAAECggEAAV5uX7qN3AnBjJl7Z6q1mX5iJdGknYGssVFagd0iTn2I\nost+TnZ9CLuk8v9ZRvjJVesG/kHYvDgX449PVo0GYCRnWvBDLiuu3Kre/gMhQcNf\npq6OZuUu5+Zc79gFwBAtJOrsJIQZOCZEfYzB7ntvPoDaVKnCG3BLfeW3kFWDE6x5\nzNwF3PyGMq4c+ctUgboBiLx/8jpmFpxq3eB415aKyquFPg1KQXdOX+vBd9MIp5qR\nq8KDIfIjm0CVptTIyiKmmsmDNbHD1DgI/fbYvXHKHqPpwGCDo/RBpJxWAOoI9kvH\nkoR5JLKJvDGgHQlHYtX1KXoLOS6v4K+uqoXV9wlO6QKBgQD6Vi3Jkz2Kl6c1fURf\nPWOLhflrhee/pkRCdtVVGleDq4TyGOSgAFuxeq4lehfbXHKDXb28nVN8/Cpj406Y\n+GnNcpW6n483BjFP7VwDSLe82a+wmlzGS6S7gp8CIprWzbRp1sdHr+bAZHilM7q6\nqn4vTyHZT4JwNszISWR4CRTyzwKBgQDcYW5HbbQ5rTYbYvU7A3+TGTGNoa9UDAhJ\nBdp8esIg0pk3HA0EQtKRHrHCUp6DJh3gwGyRRVTVl1iXTSLKnoI0fw7S5h2CEcaO\n+ypl+YT8qsIniinIm9QMi+7qOYTI4OittvO/ujMdMDxdAnskyy0kZOOJFd37kOsB\nRh3zS1OdmwKBgAgcAJG2FllF/mGqNCvNpkrfxSupg89eiHmKtfBy0QDv7neVPNq+\nCDpgmgGWye0OOptszvesNQcoeAsSUvp7mZnRK26HOrFynuhS7RciJOmWN63F4ll+\nG9EDMzlze4aX1U9UaNI2rYfv+USIv3TKjxnjO1p5y+TssYePcRS+XpJbAoGAVk6J\n48tg452kLQGKTLxIABHDyFXj1iSIMiDquglRcY1Il76SknKhCFhfAV1d2rrYxKZX\nXmUqniORfF+nGncNQwXnhky8ja3sdx6CMkGQBWvSca24Q2pTlz5OKMix6gG63h1i\nRFnlnq6/VSWdmIFBgplISu2Xa+gLQQp2vEtpybUCgYEAu2nEn2NXH1gJLk5tYiHt\nYtCmBcKaPXr9FQVLG/ome4HaoRsMFmI2nWIctNFeHOe0Cubq6x4Mr0IsiB/Z+Och\nwxTPn4tv/WU0vEpbY0IE+yiKFo0Jj4Slx7jiNglsVzULlZUAbiEWn2w7I6TaSF8b\nzK7sOnZnYY3iq+cS+9Lv3Cw=\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@grand-public-f4fd5.iam.gserviceaccount.com",
    "client_id": "114081821754437432848",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40grand-public-f4fd5.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENIR LE TOKEN D'ACCÈS OAUTH2
  // ══════════════════════════════════════════════════════════════════════════
  static Future<String> _getAccessToken() async {
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": _serviceAccount['private_key_id'],
      "private_key": _serviceAccount['private_key'],
      "client_email": _serviceAccount['client_email'],
      "client_id": _serviceAccount['client_id'],
      "type": _serviceAccount['type'],
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = http.Client();

    try {
      final AccessCredentials credentials =
          await obtainAccessCredentialsViaServiceAccount(
            accountCredentials,
            scopes,
            client,
          );
      return credentials.accessToken.data;
    } finally {
      client.close();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENVOI DEPUIS LE FRONT (appel direct à l'API FCM)
  // À utiliser uniquement en dev ou pour des cas internes
  // En prod, préférer sendFCMNotifFromBack pour ne pas exposer la clé privée
  // ══════════════════════════════════════════════════════════════════════════
  static Future<bool> sendFCMNotifFromFront({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final String accessToken = await _getAccessToken();

      final Map<String, dynamic> message = {
        "message": {
          "token": fcmToken,
          "notification": {"title": title, "body": body},
          "data": data ?? {},
          "android": {
            "priority": "HIGH",
            "notification": {
              "sound": "default",
              "channel_id": "high_importance_channel",
            },
          },
          "apns": {
            "payload": {
              "aps": {"sound": "default", "badge": 1},
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      debugPrint(
        'FCM Front response [${response.statusCode}]: ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('sendFCMNotifFromFront error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENVOI DEPUIS LE BACK (via l'API Laravel)
  // Recommandé en production — la clé privée reste côté serveur
  // ══════════════════════════════════════════════════════════════════════════
  static Future<bool> sendFCMNotifFromBack({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await RequestService().post(
        '/notifications/send',
        data: {
          'fcm_token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      debugPrint(
        'FCM Back response [${response.statusCode}]: ${response.data}',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('sendFCMNotifFromBack Dio error: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('sendFCMNotifFromBack error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER — envoie à l'utilisateur connecté
  // ══════════════════════════════════════════════════════════════════════════
  static Future<bool> sendToCurrentUser({
    required String title,
    required String body,
    Map<String, String>? data,
    bool useBackend = true,
  }) async {
    final String? fcmToken = GetStorage().read<String>('fcm_token');
    if (fcmToken == null) {
      debugPrint('Pas de FCM token disponible');
      return false;
    }

    if (useBackend) {
      return sendFCMNotifFromBack(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data,
      );
    } else {
      return sendFCMNotifFromFront(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data,
      );
    }
  }
}
