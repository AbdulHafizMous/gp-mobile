// lib/app/components/ad_banner_widget.dart
//
// Bandeau publicitaire réutilisable, à poser sur n'importe quel écran
// (accueil, club, social...). Récupère les bannières actives pour cet
// écran (GET /ads/banners?screen=...) et les affiche une par une ; chaque
// bannière peut être fermée par l'utilisateur SI le backend l'autorise
// (`dismissible`), sinon la croix de fermeture n'apparaît pas.
//
// Usage : `const AdBannerWidget(screen: 'home')` en haut d'une liste/colonne.

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';
// import 'package:url_launcher/url_launcher.dart';

class _BannerAd {
  final AdItem item;
  final int id;
  final String advertiserName;
  final String title;
  final String? body;
  final String? mediaUrl;
  final String? ctaLabel;
  final String? ctaUrl;
  final bool dismissible;

  factory _BannerAd.fromItem(AdItem i) => _BannerAd.fromJson({
    'id': i.id,
    'placement': i.placement,
    'advertiser_name': i.advertiserName,
    'title': i.title,
    'body': i.body,
    'media_type': i.mediaType,
    'media_url': i.mediaUrl,
    'cta_label': i.ctaLabel,
    'cta_url': i.ctaUrl,
    'dismissible': i.dismissible,
  });

  _BannerAd.fromJson(Map<String, dynamic> j)
    : item = AdItem.fromJson(j),
      id = j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      advertiserName = j['advertiser_name']?.toString() ?? '',
      title = j['title']?.toString() ?? '',
      body = j['body']?.toString(),
      mediaUrl = j['media_url']?.toString(),
      ctaLabel = j['cta_label']?.toString(),
      ctaUrl = j['cta_url']?.toString(),
      dismissible = j['dismissible'] != false;
}

class AdBannerWidget extends StatefulWidget {
  final String screen;

  /// Dans une chaîne : permet le ciblage par chaîne côté admin.
  final int? channelId;
  const AdBannerWidget({super.key, required this.screen, this.channelId});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  // Fermetures mémorisées pour la session en cours uniquement (pas de
  // persistance disque) : une bannière "dismissible" fermée réapparaîtra
  // à la prochaine ouverture de l'app.
  static final Set<int> _dismissedThisSession = {};

  List<_BannerAd> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AdService.fetch(
      'banner',
      screen: widget.screen,
      channelId: widget.channelId,
      limit: 3,
    );
    final list = items
        .map((i) => _BannerAd.fromItem(i))
        .where((b) => !_dismissedThisSession.contains(b.id))
        .toList();
    if (mounted) {
      setState(() {
        _banners = list;
        _loading = false;
      });
    }
  }

  int? _trackedId;

  /// Impression comptée UNE fois par bannière réellement affichée.
  void _trackOnce(_BannerAd ad) {
    if (_trackedId == ad.id) return;
    _trackedId = ad.id;
    AdService.track(ad.item, screen: widget.screen, channelId: widget.channelId);
  }

  Future<void> _openCta(_BannerAd ad) =>
      AdService.openCta(ad.item, screen: widget.screen, channelId: widget.channelId);

  @override
  Widget build(BuildContext context) {
    if (_loading || _banners.isEmpty) return const SizedBox.shrink();

    final ad = _banners.first;
    // Impression comptée une fois la bannière effectivement affichée.
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackOnce(ad));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.04),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCta(ad),
        child: Stack(
          children: [
            Row(
              children: [
                if (ad.mediaUrl != null)
                  Image.network(
                    ad.mediaUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 72, height: 72),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ad.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ad.body != null)
                          Text(
                            ad.body!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          'Sponsorisé par ${ad.advertiserName}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (ad.ctaLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      ad.ctaLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            if (ad.dismissible)
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: () => setState(() {
                    _dismissedThisSession.add(ad.id);
                    _banners.remove(ad);
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
