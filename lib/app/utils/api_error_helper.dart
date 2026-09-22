// lib/app/utils/api_error_helper.dart
//
// Point UNIQUE de transformation d'une DioException en message lisible par
// l'utilisateur. Avant, ce même bout de code (`'Erreur ${statusCode}'`)
// était dupliqué dans 4 controllers différents (chat_controller,
// social_premium_controller, dating_controller, profile_controller) — donc
// une erreur 401 s'affichait littéralement comme "Erreur 401". Tout passe
// maintenant par [ApiErrorHelper.messageFor], et le cas 401 est traduit
// clairement en "Vous êtes déconnecté".
//
// Utilisation :
//   } on DioException catch (e) {
//     ApiErrorHelper.showError(e);
//   }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class ApiErrorHelper {
  ApiErrorHelper._();

  /// Construit un message utilisateur lisible à partir d'une [DioException].
  /// Essaie d'abord le message renvoyé par le backend (`message` / `errors`),
  /// puis retombe sur un message générique par code HTTP.
  static String messageFor(DioException e) {
    final response = e.response;

    if (response == null) {
      // Pas de réponse serveur = souci réseau / timeout.
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'La connexion est trop lente. Réessayez.';
        case DioExceptionType.connectionError:
          return 'Pas de connexion internet. Vérifiez votre réseau.';
        default:
          return 'Erreur réseau. Réessayez.';
      }
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // 1) Message explicite renvoyé par le backend, si présent et exploitable.
    if (data is Map) {
      final backendMessage = data['message'];
      if (backendMessage is String && backendMessage.trim().isNotEmpty) {
        // On ne fait pas confiance aveuglément à un message générique du
        // type "Unauthenticated." pour le 401 : on garde notre propre
        // traduction dans ce cas précis (voir switch ci-dessous).
        if (statusCode != 401) return backendMessage;
      }
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final first = errors.values.isNotEmpty ? errors.values.first : null;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }

    // 2) Message générique par code HTTP.
    switch (statusCode) {
      case 401:
        return 'Vous êtes déconnecté.';
      case 403:
        return 'Action non autorisée.';
      case 404:
        return 'Ressource introuvable.';
      case 422:
        return 'Données invalides. Vérifiez les informations saisies.';
      case 429:
        return 'Trop de tentatives. Veuillez patienter quelques instants.';
      case 500:
      case 502:
      case 503:
        return 'Le serveur rencontre un problème. Réessayez plus tard.';
      default:
        return statusCode != null
            ? 'Une erreur est survenue (${statusCode}). Réessayez.'
            : 'Une erreur est survenue. Réessayez.';
    }
  }

  static bool isSessionExpired(DioException e) =>
      e.response?.statusCode == 401;

  /// Affiche directement un toast d'erreur pour une [DioException].
  static void showError(DioException e) {
    ToastHelper.showToast(
      messageFor(e),
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
