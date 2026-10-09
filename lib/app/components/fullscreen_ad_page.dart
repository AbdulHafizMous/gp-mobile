// lib/app/components/fullscreen_ad_page.dart
//
// Publicité plein écran (image ou vidéo + texte), affichée à l'entrée dans
// l'app (GET /ads/next). Jusqu'ici jamais câblée côté Flutter — le backend
// existait mais rien ne l'affichait. Voir main_page_controller / splash /
// login pour l'appel à `maybeShowFullscreenAd`.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Récupère et affiche la prochaine pub plein écran s'il y en a une.
/// Ne bloque jamais l'app : silencieux en cas d'échec/absence de pub.
/// Ne s'affiche qu'UNE fois par session app (peu importe le module ouvert
/// en premier — Grandpublic, Blowmusic ou Youwiiin appellent tous cette
/// même fonction à leur démarrage).
bool _adShownThisSession = false;

Future<void> maybeShowFullscreenAd() async {
  if (_adShownThisSession) return;
  _adShownThisSession = true;
  try {
    final res = await RequestService().get('/ads/next');
    final data = res.data?['data'];
    if (data == null) return;

    await Get.dialog(
      _FullscreenAdPage(
        adId: data['id'],
        title: data['title']?.toString() ?? '',
        body: data['body']?.toString(),
        mediaType: data['media_type']?.toString() ?? 'image',
        mediaUrl: data['media_url']?.toString(),
        advertiserName: data['advertiser_name']?.toString() ?? '',
        ctaLabel: data['cta_label']?.toString(),
        ctaUrl: data['cta_url']?.toString(),
      ),
      barrierDismissible: false,
      useSafeArea: false,
    );
  } catch (_) {
    // On ne bloque jamais l'entrée dans l'app pour une pub.
  }
}

class _FullscreenAdPage extends StatefulWidget {
  final dynamic adId;
  final String title;
  final String? body;
  final String mediaType;
  final String? mediaUrl;
  final String advertiserName;
  final String? ctaLabel;
  final String? ctaUrl;

  const _FullscreenAdPage({
    required this.adId,
    required this.title,
    required this.body,
    required this.mediaType,
    required this.mediaUrl,
    required this.advertiserName,
    required this.ctaLabel,
    required this.ctaUrl,
  });

  @override
  State<_FullscreenAdPage> createState() => _FullscreenAdPageState();
}

class _FullscreenAdPageState extends State<_FullscreenAdPage> {
  VideoPlayerController? _video;
  int _secondsLeft = 3; // le bouton fermer apparaît après un court délai

  @override
  void initState() {
    super.initState();
    _trackImpression();
    if (widget.mediaType == 'video' && widget.mediaUrl != null) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl!))
        ..initialize().then((_) {
          _video?.play();
          if (mounted) setState(() {});
        });
    }
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsLeft--);
      return _secondsLeft > 0;
    });
  }

  void _trackImpression({bool clicked = false}) {
    if (widget.adId == null) return;
    RequestService().post(
      '/ads/${widget.adId}/impression',
      data: {'clicked': clicked},
    );
  }

  Future<void> _openCta() async {
    _trackImpression(clicked: true);
    if (widget.ctaUrl == null) return;
    final uri = Uri.tryParse(widget.ctaUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.mediaType == 'video' &&
                _video != null &&
                _video!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _video!.value.size.width,
                  height: _video!.value.size.height,
                  child: VideoPlayer(_video!),
                ),
              )
            else if (widget.mediaUrl != null)
              Image.network(
                widget.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Container(color: Colors.grey.shade900),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sponsorisé par ${widget.advertiserName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.body != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.body!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (widget.ctaLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: ElevatedButton(
                          onPressed: _openCta,
                          child: Text(widget.ctaLabel!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _secondsLeft > 0
                  ? Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_secondsLeft',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : InkWell(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
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
