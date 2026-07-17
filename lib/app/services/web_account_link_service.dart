// lib/app/services/web_account_link_service.dart
//
// Conformité Apple Guideline 3.1.1 : tout paiement lié à un contenu/service
// numérique (abonnement Premium, vidéo à l'unité) doit passer par un moyen
// autre que In-App Purchase UNIQUEMENT s'il est proposé en dehors de l'app.
// On ne propose donc plus KKiaPay dans l'app : on redirige l'utilisateur vers
// le site web (grandpublic.bj) où il peut payer librement (Mobile Money,
// carte bancaire, etc.).
//
// Comme certains comptes sont créés via Apple/Google (pas de mot de passe,
// parfois pas d'email joignable), on ne demande pas à l'utilisateur de se
// reconnecter sur le site : on génère depuis l'app (déjà authentifiée via
// Sanctum) un lien à usage unique et de courte durée qui connecte
// automatiquement l'utilisateur sur le site au clic.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class WebAccountLinkService {
  /// Ouvre le navigateur externe sur l'espace "Mon compte" du site,
  /// automatiquement connecté grâce à un token signé à usage unique.
  ///
  /// [intent] : 'subscribe' pour l'écran d'abonnement Premium,
  ///            'media' pour l'achat d'une vidéo précise (fournir [mediaId]).
  /// [planId] : présélectionne un plan d'abonnement sur la page web.
  static Future<void> openWebAccount({
    String intent = 'subscribe',
    int? mediaId,
    int? planId,
  }) async {
    try {
      if (useMock) {
        await ToastHelper.showToast(
          '[Mock] Ouverture du site pour : $intent',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      final response = await RequestService().post(
        '/account/web-link',
        data: {
          'intent': intent,
          if (mediaId != null) 'media_id': mediaId,
          if (planId != null) 'subscription_plan_id': planId,
        },
      );

      final url = response.data?['data']?['url']?.toString();

      if (url == null || url.isEmpty) {
        await ToastHelper.showToast(
          "Impossible d'ouvrir le site pour le moment. Réessayez.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        await ToastHelper.showToast(
          "Impossible d'ouvrir le navigateur.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('WebAccountLinkService error: $e');
      await ToastHelper.showToast(
        "Impossible d'ouvrir le site pour le moment. Réessayez plus tard.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
