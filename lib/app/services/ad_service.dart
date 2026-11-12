// lib/app/services/ad_service.dart
//
// Moteur de publicité côté app, commun à TOUS les modules (Grandpublic,
// Blowmusic, Youwiiin) et aux Chaînes. Le contexte (module, chaîne, écran) est
// envoyé au backend, qui applique le ciblage défini dans l'admin
// (GET /ads/serve) et enregistre les impressions / clics par module.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/ad_interstitial_page.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:url_launcher/url_launcher.dart';

class AdItem {
  final int id;
  final String placement;
  final String advertiserName;
  final String title;
  final String? body;
  final String? mediaType; // image | video
  final String? mediaUrl;
  final String? ctaLabel;
  final String? ctaUrl;
  final bool dismissible;
  final int frequencyEvery;
  final int skipAfterSeconds;

  AdItem.fromJson(Map<String, dynamic> j)
    : id = j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      placement = j['placement']?.toString() ?? '',
      advertiserName = j['advertiser_name']?.toString() ?? '',
      title = j['title']?.toString() ?? '',
      body = j['body']?.toString(),
      mediaType = j['media_type']?.toString(),
      mediaUrl = j['media_url']?.toString(),
      ctaLabel = j['cta_label']?.toString(),
      ctaUrl = j['cta_url']?.toString(),
      dismissible = j['dismissible'] != false,
      frequencyEvery = j['frequency_every'] is int ? j['frequency_every'] : 6,
      skipAfterSeconds = j['skip_after_seconds'] is int ? j['skip_after_seconds'] : 5;
}

class AdService {
  AdService._();

  /// Module courant pour le ciblage publicitaire.
  static String module({int? channelId}) {
    if (channelId != null) return 'channels';
    switch (AppModeService.current) {
      case AppMode.blowMusic:
        return 'blowmusic';
      case AppMode.youwiiin:
        return 'youwiiin';
      case AppMode.grandPublic:
        return 'grandpublic';
    }
  }

  /// Annonces éligibles pour un emplacement. Jamais bloquant : [] en cas d'erreur.
  static Future<List<AdItem>> fetch(
    String placement, {
    String? screen,
    int? channelId,
    int limit = 3,
  }) async {
    try {
      final res = await RequestService().get(
        '/ads/serve',
        queryParameters: {
          'placement': placement,
          'module': module(channelId: channelId),
          if (screen != null) 'screen': screen,
          if (channelId != null) 'channel_id': channelId,
          'limit': limit,
        },
      );
      return (res.data?['data'] as List<dynamic>? ?? [])
          .map((j) => AdItem.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Enregistre un affichage (ou un clic). Retourne l'id d'affichage (pour [trackEnd]).
  static Future<int?> track(
    AdItem ad, {
    bool clicked = false,
    String? screen,
    int? channelId,
  }) async {
    try {
      final res = await RequestService().post(
        '/ads/${ad.id}/impression',
        data: {
          'event': clicked ? 'click' : 'view',
          'module': module(channelId: channelId),
          if (screen != null) 'screen': screen,
          if (channelId != null) 'channel_id': channelId,
        },
      );
      final id = res.data?['data']?['impression_id'];
      return id is int ? id : int.tryParse('$id');
    } catch (_) {
      return null;
    }
  }

  /// Fin de visionnage : durée réellement vue, vidéo terminée ou passée.
  static Future<void> trackEnd(
    AdItem ad,
    int? impressionId, {
    required int watchSeconds,
    required bool completed,
    required bool skipped,
  }) async {
    if (impressionId == null) return;
    try {
      await RequestService().post(
        '/ads/${ad.id}/impression',
        data: {
          'event': 'end',
          'impression_id': impressionId,
          'watch_seconds': watchSeconds,
          'completed': completed,
          'skipped': skipped,
        },
      );
    } catch (_) {}
  }

  static Future<void> openCta(AdItem ad, {String? screen, int? channelId}) async {
    track(ad, clicked: true, screen: screen, channelId: channelId);
    final uri = ad.ctaUrl == null ? null : Uri.tryParse(ad.ctaUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Affiche (si une annonce existe) une pub plein écran.
  /// [placement] : 'interstitial' ou 'preroll'. Retourne quand elle est fermée.
  static Future<void> showFullscreen(
    BuildContext context,
    String placement, {
    int? channelId,
    String? screen,
  }) async {
    final ads = await fetch(placement, channelId: channelId, screen: screen, limit: 1);
    if (ads.isEmpty || !context.mounted) return;
    await presentFullscreen(Navigator.of(context), ads.first, channelId: channelId, screen: screen);
  }

  // ── Fréquence : jamais plus d'une pub plein écran toutes les [minGap] et toutes les [every] occurrences ──
  static final Map<String, int> _counters = {};
  static DateTime? _lastFullscreen;

  /// Point d'entrée UNIQUE des interstitiels « sur événement » (fin de jeu, Nième titre, Nième article…).
  /// [key] identifie le compteur (ex. 'bm_track', 'game_end'), [every] le rythme.
  /// Ne bloque jamais, ne montre rien s'il n'y a pas d'annonce.
  static Future<void> maybeInterstitial(
    String key, {
    int every = 4,
    String? screen,
    int? channelId,
    Duration minGap = const Duration(seconds: 90),
    String placement = 'interstitial',
  }) async {
    final n = (_counters[key] ?? 0) + 1;
    _counters[key] = n;
    if (n % every != 0) return;
    final last = _lastFullscreen;
    if (last != null && DateTime.now().difference(last) < minGap) return;
    final ctx = Get.context;
    if (ctx == null || !ctx.mounted) return;
    _lastFullscreen = DateTime.now();
    await showFullscreen(ctx, placement, channelId: channelId, screen: screen ?? key);
  }
}
