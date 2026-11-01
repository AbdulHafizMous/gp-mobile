// lib/app/utils/auth_diagnostics.dart
//
// Rend visibles les VRAIES erreurs de connexion sociale (Google / Apple) au
// lieu d'un « La connexion avec Google a échoué ». Affiche : l'étape qui a
// planté, le type d'exception, son code, sa description et ses détails natifs,
// avec un bouton « Copier » (utile en TestFlight, où on n'a pas la console).
//
// À désactiver (kAuthDebugDialog = false) une fois le problème iOS résolu.

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// true = affiche une boîte de dialogue détaillée à chaque échec (même en release).
const bool kAuthDebugDialog = true;

class AuthDiagnostics {
  AuthDiagnostics._();

  /// Décrit une exception avec tout ce qu'elle contient.
  static String describe(Object e) {
    if (e is GoogleSignInException) {
      return 'GoogleSignInException\n'
          '  code        : ${e.code.name}\n'
          '  description : ${e.description}\n'
          '  details     : ${e.details}';
    }
    if (e is FirebaseAuthException) {
      return 'FirebaseAuthException\n'
          '  code    : ${e.code}\n'
          '  message : ${e.message}\n'
          '  plugin  : ${e.plugin}';
    }
    if (e is PlatformException) {
      return 'PlatformException\n'
          '  code    : ${e.code}\n'
          '  message : ${e.message}\n'
          '  details : ${e.details}';
    }
    if (e is DioException) {
      return 'DioException\n'
          '  type    : ${e.type.name}\n'
          '  status  : ${e.response?.statusCode}\n'
          '  message : ${e.message}\n'
          '  body    : ${e.response?.data}';
    }
    return '${e.runtimeType}\n  $e';
  }

  /// Piste de cause probable (null si on n'en a pas de fiable).
  static String? hint(Object e) {
    if (e is GoogleSignInException) {
      switch (e.code.name) {
        case 'clientConfigurationError':
          return 'GoogleService-Info.plist absent/périmé (sans CLIENT_ID), '
              'clientId incorrect, ou schéma URL REVERSED_CLIENT_ID manquant '
              'dans ios/Runner/Info.plist.';
        case 'uiUnavailable':
          return 'Aucun écran pour présenter la fenêtre Google (typique sur '
              'iPad / cycle UIScene) : vérifier la version de google_sign_in_ios '
              'et le rootViewController.';
        case 'providerConfigurationError':
          return 'Le fournisseur Google est indisponible ou mal configuré sur cet appareil.';
      }
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
          return 'Firebase refuse le jeton Google : l\'audience (clientId / '
              'serverClientId) n\'appartient pas à ce projet Firebase, ou '
              'l\'heure de l\'appareil est fausse.';
        case 'operation-not-allowed':
          return 'Fournisseur désactivé : Firebase > Authentication > Sign-in method.';
        case 'keychain-error':
        case 'internal-error':
          return 'iOS : activer « Keychain Sharing » (Signing & Capabilities) '
              'et vérifier que l\'app est bien signée.';
        case 'network-request-failed':
          return 'Problème réseau côté Firebase.';
      }
    }
    if (e is PlatformException && e.code.toLowerCase().contains('keychain')) {
      return 'iOS : problème de Keychain (capability « Keychain Sharing » / signature).';
    }
    return null;
  }

  static void report({
    required String provider,
    required String step,
    required Object error,
    StackTrace? stack,
  }) {
    final hint0 = hint(error);
    final text =
        '[$provider] étape : $step\n'
        'plateforme : ${defaultTargetPlatform.name}\n\n'
        '${describe(error)}'
        '${hint0 != null ? '\n\nPiste : $hint0' : ''}';

    debugPrint('❌ AUTH\n$text\n${stack ?? ''}');
    if (!kAuthDebugDialog) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Détail de l\'erreur'),
        content: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: const Text('Copier'),
          ),
          TextButton(onPressed: Get.back, child: const Text('Fermer')),
        ],
      ),
    );
  }
}
