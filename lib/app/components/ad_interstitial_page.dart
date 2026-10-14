// Pub plein écran (interstitiel / pré-roll) : image ou vidéo, bouton
// « Passer » après N secondes (0 = non passable), CTA cliquable.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';
import 'package:video_player/video_player.dart';

class AdInterstitialPage extends StatefulWidget {
  final AdItem ad;
  final int? channelId;
  final String? screen;
  const AdInterstitialPage({super.key, required this.ad, this.channelId, this.screen});

  @override
  State<AdInterstitialPage> createState() => _AdInterstitialPageState();
}

class _AdInterstitialPageState extends State<AdInterstitialPage> {
  VideoPlayerController? _video;
  Timer? _timer;
  late int _left;

  @override
  void initState() {
    super.initState();
    _left = widget.ad.skipAfterSeconds;
    AdService.track(widget.ad, screen: widget.screen, channelId: widget.channelId);
    if (widget.ad.mediaType == 'video' && widget.ad.mediaUrl != null) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.ad.mediaUrl!))
        ..initialize().then((_) {
          if (!mounted) return;
          _video!
            ..setLooping(true)
            ..play();
          setState(() {});
        });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left > 0 && mounted) setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  bool get _canSkip => widget.ad.skipAfterSeconds > 0 && _left <= 0;

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return PopScope(
      canPop: _canSkip,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          if (_video != null && _video!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _video!.value.size.width,
                height: _video!.value.size.height,
                child: VideoPlayer(_video!),
              ),
            )
          else if (ad.mediaUrl != null && ad.mediaType != 'video')
            Image.network(ad.mediaUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          // Dégradé de lisibilité
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Publicité', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  if (ad.skipAfterSeconds > 0)
                    GestureDetector(
                      onTap: _canSkip ? () => Navigator.of(context).pop() : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          _canSkip ? 'Passer ✕' : 'Passer dans $_left s',
                          style: TextStyle(color: _canSkip ? Colors.white : Colors.white60, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                ]),
                const Spacer(),
                Text(ad.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                if (ad.body != null) ...[
                  const SizedBox(height: 6),
                  Text(ad.body!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
                const SizedBox(height: 4),
                Text('Sponsorisé par ${ad.advertiserName}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                if (ad.ctaLabel != null && ad.ctaUrl != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => AdService.openCta(ad, screen: widget.screen, channelId: widget.channelId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(ad.ctaLabel!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
