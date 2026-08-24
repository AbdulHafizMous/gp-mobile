import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// ⚠️ NOTE SÉCURITÉ (22/08/2026)
/// ─────────────────────────────────────────────────────────────────────────
/// Cette classe contenait auparavant la clé privée complète du compte de
/// service Firebase (JSON, RSA) codée en dur dans le code source mobile,
/// ainsi qu'un appel FCM direct depuis le front (`sendFCMNotifFromFront`).
/// N'importe qui décompilant l'APK pouvait extraire cette clé et envoyer
/// des notifications push à tous les utilisateurs en usurpant l'identité
/// de l'app (voire abuser d'autres droits IAM du compte de service).
///
/// → Cette clé a été retirée. Tout envoi passe désormais exclusivement par
///   le backend (`/notifications/send`), qui gère le token OAuth2 côté
///   serveur (`NotificationService::getAccessToken`), là où une clé privée
///   peut être stockée en toute sécurité.
///
/// ACTION REQUISE côté Firebase : régénérer/révoquer la clé de compte de
/// service qui a été exposée dans le code (Firebase Console → Paramètres
/// du projet → Comptes de service → Gérer les clés), puis mettre à jour
/// `storage/app/firebase-service-account.json` côté backend avec la
/// nouvelle clé.
/// ─────────────────────────────────────────────────────────────────────────
class FCMService {
  /// Envoi via le backend — le seul chemin autorisé en production.
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

  /// Helper — envoie à l'utilisateur connecté (toujours via le backend).
  static Future<bool> sendToCurrentUser({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final String? fcmToken = GetStorage().read<String>('fcm_token');
    if (fcmToken == null) {
      debugPrint('Pas de FCM token disponible');
      return false;
    }

    return sendFCMNotifFromBack(
      fcmToken: fcmToken,
      title: title,
      body: body,
      data: data,
    );
  }
}
