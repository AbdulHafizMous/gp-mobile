// lib/app/components/ad_interstitial_page.dart
//
// Pub plein écran UNIQUE de l'app : entrée dans l'app (fullscreen_entry),
// interstitiel et pré-roll passent tous par ici.
//
// Règles (corrige la pub vidéo qui disparaissait au bout de 3 s) :
//  • VIDÉO : jouée jusqu'au bout, une seule fois. « Passer » n'apparaît qu'après
//    `skip_after_seconds` (0 = non passable, la pub se ferme à la fin de la vidéo).
//    Jamais fermée par un timer fixe.
//  • IMAGE : affichée au moins `skip_after_seconds` (défaut 5 s) avant de pouvoir fermer.
//  • La route ignore les `Get.back()` / `Navigator.pop()` parasites (ex. fermeture
//    d'un loader au démarrage) : seule la pub elle-même la ferme.
//  • Suivi : affichage, clic, durée réellement vue, fin de vidéo, passage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/services/ad_service.dart';
import 'package:video_player/video_player.dart';

/// Route qui ne se ferme que via [close] (pas par un pop parasite).
class _AdRoute extends PageRouteBuilder<void> {
  bool _open = true;

  _AdRoute(WidgetBuilder builder)
    : super(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, _, __) => builder(ctx),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      );

  @override
  bool get willHandlePopInternally => _open;

  @override
  bool didPop(void result) {
    if (_open) return false; // pop parasite ignoré
    return super.didPop(result);
  }

  void close() {
    if (!_open) return;
    _open = false;
    navigator?.removeRoute(this);
  }
}

/// Affiche [ad] en plein écran et retourne à sa fermeture.
Future<void> presentFullscreen(
  NavigatorState nav,
  AdItem ad, {
  int? channelId,
  String? screen,
}) async {
  late final _AdRoute route;
  route = _AdRoute(
    (_) => AdInterstitialPage(
      ad: ad,
      channelId: channelId,
      screen: screen,
      onClose: () => route.close(),
    ),
  );
  await nav.push(route);
}

class AdInterstitialPage extends StatefulWidget {
  final AdItem ad;
  final int? channelId;
  final String? screen;
  final VoidCallback onClose;
  const AdInterstitialPage({
    super.key,
    required this.ad,
    required this.onClose,
    this.channelId,
    this.screen,
  });

  @override
  State<AdInterstitialPage> createState() => _AdInterstitialPageState();
}

class _AdInterstitialPageState extends State<AdInterstitialPage> {
  static const _imageMinSeconds = 5;

  VideoPlayerController? _video;
  Timer? _timer;
  int? _impressionId;
  int _elapsed = 0; // secondes écoulées depuis l'affichage
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _videoDone = false;
  bool _muted = false;
  bool _closed = false;

  AdItem get ad => widget.ad;
  bool get _isVideo => ad.mediaType == 'video' && ad.mediaUrl != null && !_videoFailed;

  /// Délai avant « Passer ». Image : au moins [_imageMinSeconds] si non configuré.
  int get _skipAfter => ad.skipAfterSeconds > 0 ? ad.skipAfterSeconds : (_isVideo ? 0 : _imageMinSeconds);

  /// Vidéo non passable (skip=0) : seule la fin de la vidéo ferme la pub.
  bool get _canSkip {
    if (_isVideo && ad.skipAfterSeconds == 0) return _videoDone;
    return _elapsed >= _skipAfter || _videoDone;
  }

  @override
  void initState() {
    super.initState();
    AdService.track(ad, screen: widget.screen, channelId: widget.channelId).then((id) => _impressionId = id);
    if (_isVideo) _initVideo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Le compteur n'avance que quand la vidéo joue vraiment (pas pendant le chargement).
      if (_isVideo && !_videoReady) return;
      setState(() => _elapsed++);
    });
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(ad.mediaUrl!));
      _video = c;
      await c.initialize();
      if (!mounted) return;
      await c.setLooping(false);
      c.addListener(_onVideoTick);
      await c.play();
      setState(() => _videoReady = true);
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true); // retombe sur l'affichage image/texte
    }
  }

  void _onVideoTick() {
    final v = _video?.value;
    if (v == null || _videoDone) return;
    if (v.hasError) {
      setState(() => _videoFailed = true);
      return;
    }
    if (v.isInitialized && v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 250)) {
      setState(() => _videoDone = true);
      // Fin de la vidéo : on laisse l'écran final 1,5 s (CTA visible) puis fermeture douce si non cliquable.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && ad.ctaUrl == null) _finish(skipped: false);
      });
    }
  }

  void _finish({required bool skipped}) {
    if (_closed) return;
    _closed = true;
    final watched = (_video?.value.position.inSeconds ?? _elapsed).clamp(0, 3600);
    AdService.trackEnd(
      ad,
      _impressionId,
      watchSeconds: _isVideo ? watched : _elapsed,
      completed: _videoDone,
      skipped: skipped && !_videoDone,
    );
    widget.onClose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    if (!_closed) {
      _closed = true;
      AdService.trackEnd(ad, _impressionId, watchSeconds: _elapsed, completed: _videoDone, skipped: false);
    }
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _video?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final showVideo = _isVideo && _videoReady && _video != null && _video!.value.isInitialized;
    final v = _video?.value;
    final total = (v != null && v.isInitialized) ? v.duration.inMilliseconds : 0;
    final progress = total > 0 ? (v!.position.inMilliseconds / total).clamp(0.0, 1.0) : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canSkip) _finish(skipped: true);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [
          if (showVideo)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _video!.value.size.width,
                height: _video!.value.size.height,
                child: VideoPlayer(_video!),
              ),
            )
          else if (ad.mediaUrl != null && (ad.mediaType != 'video' || _videoFailed))
            Image.network(ad.mediaUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
          else if (_isVideo)
            const Center(child: CircularProgressIndicator(color: Colors.white54)),
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
                if (showVideo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Publicité', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  if (showVideo)
                    IconButton(
                      onPressed: _toggleMute,
                      icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                    ),
                  _skipButton(),
                ]),
                const Spacer(),
                Text(ad.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                if (ad.body != null && ad.body!.isNotEmpty) ...[
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

  Widget _skipButton() {
    if (_canSkip) {
      return GestureDetector(
        onTap: () => _finish(skipped: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: const Text('Fermer ✕', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
    }
    // Vidéo non passable : pas de bouton, juste le temps restant.
    if (_isVideo && ad.skipAfterSeconds == 0) {
      final v = _video?.value;
      final left = (v != null && v.isInitialized) ? (v.duration - v.position).inSeconds + 1 : null;
      return left == null
          ? const SizedBox.shrink()
          : Text('$left s', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700));
    }
    final left = (_skipAfter - _elapsed).clamp(0, 999);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Text('Passer dans $left s', style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
