// lib/app/components/fullscreen_ad_page.dart
//
// Publicité plein écran à l'entrée dans l'app (GET /ads/next).
// L'affichage lui-même est celui de `AdInterstitialPage` (même moteur que les
// interstitiels et pré-roll) : vidéo jouée jusqu'au bout, « Passer » selon la
// configuration de l'annonce, suivi du temps vu. Voir ad_interstitial_page.dart.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/ad_interstitial_page.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

/// Une seule fois par session app, quel que soit le module ouvert en premier
/// (Grandpublic, Blowmusic ou Youwiiin appellent tous cette fonction).
bool _adShownThisSession = false;

/// Récupère et affiche la pub d'entrée s'il y en a une. Ne bloque jamais l'app.
Future<void> maybeShowFullscreenAd() async {
  if (_adShownThisSession) return;
  _adShownThisSession = true;
  try {
    final res = await RequestService().get(
      '/ads/next',
      queryParameters: {'module': AdService.module()},
    );
    final data = res.data?['data'];
    if (data == null) return;
    final ad = AdItem.fromJson(Map<String, dynamic>.from(data as Map));

    // Laisse l'écran d'accueil finir de s'installer (loaders / transitions de démarrage).
    await Future<void>.delayed(const Duration(milliseconds: 600));

    NavigatorState? nav = Get.key.currentState;
    for (var i = 0; nav == null && i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      nav = Get.key.currentState;
    }
    if (nav == null) return;

    await presentFullscreen(nav, ad, screen: 'entry');
  } catch (_) {
    // On ne bloque jamais l'entrée dans l'app pour une pub.
  }
}
