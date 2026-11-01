// lib/app/components/mini_media.dart
//
// Fenêtre vidéo flottante (« Réduire » de VidDetail) : la vidéo continue dans
// une petite fenêtre déplaçable au-dessus de toute l'app. Vidéo hébergée chez
// nous (VideoPlayer) ou YouTube (youtube_player_flutter).
//
// API utilisée par VidDetail :
//   MiniMedia.minimize(video, position, playing)  → ouvre la fenêtre
//   MiniMedia.close()                              → ferme la fenêtre (garde la reprise)
//   MiniMedia.hasSeek / MiniMedia.takeSeek()       → reprise après « Agrandir »
//
// ⚠️ Comme BmMiniPlayerOverlay, ce widget vit AU-DESSUS du Navigator (builder
// de GetMaterialApp) : on navigue via Get.*, pas via Navigator.of(context).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/bm_mini_player.dart'
    show currentRouteName, kOverlayHiddenRoutes;
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/modules/blowmusic/controllers/blowmusic_controller.dart';
import 'package:grand_public_v2/app/modules/pages/vid_detail.dart';
import 'package:grand_public_v2/app/modules/videos/controllers/videos_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ÉTAT GLOBAL
// ─────────────────────────────────────────────────────────────────────────────
class _MiniRequest {
  _MiniRequest(this.video, this.startAt, this.autoPlay) : token = ++_counter;
  static int _counter = 0;

  final SpaceVideo video;
  final Duration startAt;
  final bool autoPlay;

  /// Identifie CETTE ouverture : une nouvelle vidéo réduite recrée le lecteur.
  final int token;
}

class MiniMedia {
  MiniMedia._();

  static final Rxn<_MiniRequest> _current = Rxn<_MiniRequest>();

  // Position de reprise transmise à VidDetail après « Agrandir ». Elle expire :
  // si l'écran complet ne la consomme pas (article, média verrouillé…), elle ne
  // doit pas contaminer une ouverture ultérieure.
  static Duration? _seek;
  static DateTime? _seekAt;
  static const _seekTtl = Duration(seconds: 60);

  static bool get isActive => _current.value != null;

  static bool get hasSeek =>
      _seek != null &&
      _seekAt != null &&
      DateTime.now().difference(_seekAt!) < _seekTtl;

  /// Renvoie la position de reprise (une seule fois) puis l'oublie.
  static Duration? takeSeek() {
    final s = hasSeek ? _seek : null;
    _seek = null;
    _seekAt = null;
    return s;
  }

  /// Réduit [video] en fenêtre flottante, à [position], en lecture si [playing].
  static void minimize(SpaceVideo video, Duration position, bool playing) {
    _seek = null;
    _seekAt = null;
    if (playing) _pauseBlowmusic();
    _current.value = _MiniRequest(video, position, playing);
  }

  /// Ferme la fenêtre (appelé par VidDetail dans initState : un seul lecteur à
  /// la fois). Ne touche PAS à la reprise, que VidDetail lit juste après.
  static void close() {
    if (_current.value == null) return;
    // initState tourne pendant le build : on ne modifie pas un Rx observé
    // ailleurs dans l'arbre à ce moment-là.
    Future.microtask(() => _current.value = null);
  }

  /// Fermeture par l'utilisateur (✕) : on oublie aussi toute reprise.
  static void dismiss() {
    _seek = null;
    _seekAt = null;
    _current.value = null;
  }

  /// « Agrandir » : rouvre l'écran complet à la position courante.
  static void _expand(SpaceVideo video, Duration position) {
    _seek = position;
    _seekAt = DateTime.now();
    _current.value = null;
    if (!Get.isRegistered<VideosController>()) Get.put(VideosController());
    // VidDetail affiche `currentVideo ?? widget.video` : on l'aligne.
    Get.find<VideosController>().currentVideo.value = video;
    Get.to(() => VidDetail(video: video));
  }

  /// Un seul son à la fois : si Blowmusic joue, on le met en pause.
  static void _pauseBlowmusic() {
    if (!Get.isRegistered<BlowMusicController>() ||
        Get.isPrepared<BlowMusicController>()) {
      return;
    }
    final bm = Get.find<BlowMusicController>();
    if (bm.isPlaying.value) unawaited(bm.togglePlayPause());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY (déplaçable, s'accroche au bord gauche/droit)
// ─────────────────────────────────────────────────────────────────────────────
class MiniMediaOverlay extends StatefulWidget {
  const MiniMediaOverlay({super.key});

  @override
  State<MiniMediaOverlay> createState() => _MiniMediaOverlayState();
}

class _MiniMediaOverlayState extends State<MiniMediaOverlay> {
  static const double _margin = 12;
  Offset? _pos; // coin haut-gauche ; null = position par défaut
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final req = MiniMedia._current.value;
      if (req == null || kOverlayHiddenRoutes.contains(currentRouteName.value)) {
        return const SizedBox.shrink();
      }

      final video = req.video;
      // Format vertical seulement pour nos fichiers (le player YouTube reste 16:9).
      final portrait = video.isPortrait && video.sourceType == 'upload';
      final w = portrait ? 128.0 : 232.0;
      final h = portrait ? w * 16 / 9 : w * 9 / 16;

      final mq = MediaQuery.of(context);
      final minX = _margin;
      final maxX = math.max(minX, mq.size.width - w - _margin);
      final minY = mq.padding.top + _margin;
      final maxY = math.max(minY, mq.size.height - h - mq.padding.bottom - _margin);

      // Par défaut : en bas à droite, au-dessus de la bottom bar et du
      // mini-lecteur Blowmusic.
      final p = _pos ?? Offset(maxX, maxY - 150);
      final dx = p.dx.clamp(minX, maxX).toDouble();
      final dy = p.dy.clamp(minY, maxY).toDouble();

      return AnimatedPositioned(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        left: dx,
        top: dy,
        width: w,
        height: h,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _dragging = true),
          onPanUpdate: (d) => setState(
            () => _pos = Offset(dx + d.delta.dx, dy + d.delta.dy),
          ),
          onPanEnd: (_) => setState(() {
            _dragging = false;
            // Aimantation au bord le plus proche.
            final snapX = dx + w / 2 < mq.size.width / 2 ? minX : maxX;
            _pos = Offset(snapX, dy);
          }),
          child: _MiniMediaWindow(
            key: ValueKey(req.token),
            request: req,
            width: w,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FENÊTRE (lecteur + contrôles)
// ─────────────────────────────────────────────────────────────────────────────
class _Snap {
  const _Snap({
    this.ready = false,
    this.playing = false,
    this.buffering = false,
    this.error = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final bool ready, playing, buffering, error;
  final Duration position, duration;
}

class _MiniMediaWindow extends StatefulWidget {
  const _MiniMediaWindow({super.key, required this.request, required this.width});

  final _MiniRequest request;
  final double width;

  @override
  State<_MiniMediaWindow> createState() => _MiniMediaWindowState();
}

class _MiniMediaWindowState extends State<_MiniMediaWindow> {
  VideoPlayerController? _native;
  YoutubePlayerController? _yt;
  final ValueNotifier<_Snap> _snap = ValueNotifier<_Snap>(const _Snap());

  bool _controls = true;
  bool _disposed = false;
  Timer? _hideTimer;

  SpaceVideo get _video => widget.request.video;

  @override
  void initState() {
    super.initState();
    final url = _video.videoFileUrl;
    if (_video.sourceType == 'upload' && url != null && url.isNotEmpty) {
      _initNative(url);
    } else {
      _initYoutube();
    }
    _armHide();
  }

  // ── Initialisation ────────────────────────────────────────────────────────
  Future<void> _initNative(String url) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _native = c;
    c.addListener(_onNative);
    try {
      await c.initialize();
      if (_disposed) return;
      if (widget.request.startAt > Duration.zero) {
        await c.seekTo(widget.request.startAt);
      }
      if (_disposed) return;
      if (widget.request.autoPlay) await c.play();
      if (_disposed) return;
      _onNative();
      setState(() {}); // la surface VideoPlayer peut maintenant s'afficher
    } catch (e) {
      debugPrint('MiniMedia: erreur de lecture native : $e');
      if (!_disposed) _snap.value = const _Snap(error: true);
    }
  }

  void _initYoutube() {
    final id = _youtubeId(_video);
    if (id == null) {
      _snap.value = const _Snap(error: true);
      return;
    }
    _yt = YoutubePlayerController(
      initialVideoId: id,
      flags: YoutubePlayerFlags(
        autoPlay: widget.request.autoPlay,
        startAt: widget.request.startAt.inSeconds,
        hideControls: true,
        enableCaption: false,
        forceHD: false,
      ),
    )..addListener(_onYt);
  }

  String? _youtubeId(SpaceVideo v) {
    final raw = v.youtubeId.isNotEmpty ? v.youtubeId : v.videoUrl;
    final id = YoutubePlayer.convertUrlToId(raw);
    if (id != null && id.isNotEmpty) return id;
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(raw) ? raw : null;
  }

  // ── Écoute des lecteurs ───────────────────────────────────────────────────
  void _onNative() {
    final c = _native;
    if (c == null) return;
    final v = c.value;
    _publish(_Snap(
      ready: v.isInitialized,
      playing: v.isPlaying,
      buffering: v.isBuffering,
      error: v.hasError,
      position: v.position,
      duration: v.duration,
    ));
  }

  void _onYt() {
    final c = _yt;
    if (c == null) return;
    final v = c.value;
    _publish(_Snap(
      ready: v.isReady,
      playing: v.isPlaying,
      buffering: v.playerState == PlayerState.buffering,
      error: v.hasError,
      position: v.position,
      duration: v.metaData.duration,
    ));
  }

  /// Ne notifie que si quelque chose de visible change (évite de redessiner
  /// la fenêtre à chaque tick du lecteur).
  void _publish(_Snap s) {
    if (_disposed) return;
    final o = _snap.value;
    if (s.ready == o.ready &&
        s.playing == o.playing &&
        s.buffering == o.buffering &&
        s.error == o.error &&
        s.duration == o.duration &&
        (s.position - o.position).inMilliseconds.abs() < 500) {
      return;
    }
    _snap.value = s;
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _toggle() {
    final playing = _snap.value.playing;
    if (!playing) MiniMedia._pauseBlowmusic();
    final n = _native;
    final y = _yt;
    if (n != null) {
      playing ? n.pause() : n.play();
    } else if (y != null) {
      playing ? y.pause() : y.play();
    }
    _armHide();
  }

  void _expand() => MiniMedia._expand(_video, _snap.value.position);

  void _onTapSurface() {
    if (_controls) {
      setState(() => _controls = false);
    } else {
      _armHide();
    }
  }

  /// Affiche les contrôles puis les masque après 3 s (si la lecture tourne).
  void _armHide() {
    _hideTimer?.cancel();
    if (!_controls) setState(() => _controls = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _snap.value.playing) setState(() => _controls = false);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _hideTimer?.cancel();
    _native?.removeListener(_onNative);
    _native?.dispose();
    _yt?.removeListener(_onYt);
    _yt?.dispose();
    _snap.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  Widget _surface() {
    final n = _native;
    if (n != null && n.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: n.value.size.width,
          height: n.value.size.height,
          child: VideoPlayer(n),
        ),
      );
    }
    final y = _yt;
    if (y != null) {
      // IgnorePointer : le WebView ne doit pas voler les gestes (déplacement, tap).
      return IgnorePointer(
        child: YoutubePlayer(
          controller: y,
          width: widget.width,
          aspectRatio: 16 / 9,
          showVideoProgressIndicator: false,
          topActions: const [],
          bottomActions: const [],
        ),
      );
    }
    return Image.network(
      _video.thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;

    return Material(
      color: Colors.black,
      elevation: 12,
      shadowColor: Colors.black87,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _surface(),
            ValueListenableBuilder<_Snap>(
              valueListenable: _snap,
              builder: (_, s, __) {
                final showControls = _controls || !s.playing;
                final progress = s.duration.inMilliseconds > 0
                    ? (s.position.inMilliseconds / s.duration.inMilliseconds)
                          .clamp(0.0, 1.0)
                          .toDouble()
                    : 0.0;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Chargement / mise en mémoire tampon
                    if (!s.error && (!s.ready || s.buffering))
                      const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    // Erreur
                    if (s.error)
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 22),
                            SizedBox(height: 4),
                            Text(
                              'Lecture impossible',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                    // Contrôles (fondu)
                    IgnorePointer(
                      ignoring: !showControls,
                      child: AnimatedOpacity(
                        opacity: showControls ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black54, Colors.transparent, Colors.black54],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: _MiniBtn(
                                icon: Icons.open_in_full_rounded,
                                onTap: _expand,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _MiniBtn(
                                icon: Icons.close_rounded,
                                onTap: MiniMedia.dismiss,
                              ),
                            ),
                            if (!s.error)
                              Center(
                                child: GestureDetector(
                                  onTap: _toggle,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: .45),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      s.playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Progression : toujours visible
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2.5,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }
}
