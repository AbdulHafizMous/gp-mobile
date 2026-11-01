// lib/app/components/bm_mini_player.dart
//
// Mini-lecteur Blowmusic flottant, superposé à TOUTE l'app (voir le `builder`
// de GetMaterialApp dans main.dart). Il apparaît dès qu'un titre ou le direct
// est en cours et que l'utilisateur est HORS de l'écran Blowmusic (qui a déjà
// son propre mini-lecteur dans sa bottom bar) et hors du lecteur plein écran.
//
// ⚠️ Ce widget vit AU-DESSUS du Navigator : pas de Overlay (donc pas de
// Tooltip), pas de Material ancestor → on en ajoute un, et on navigue avec
// Get.* / Get.overlayContext, jamais avec Navigator.of(context).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/vinyl_disc.dart';
import 'package:grand_public_v2/app/modules/blowmusic/controllers/blowmusic_controller.dart';
import 'package:grand_public_v2/app/modules/blowmusic/views/bm_player_page.dart';
import 'package:grand_public_v2/app/routes/app_pages.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

/// Route courante, alimentée par `routingCallback` dans main.dart.
/// Sert aux deux overlays (Blowmusic + MiniMedia) à se masquer / se réafficher.
final RxString currentRouteName = ''.obs;

/// Écrans où AUCUN mini-lecteur flottant ne doit apparaître.
const Set<String> kOverlayHiddenRoutes = {
  Routes.SPLASH,
  Routes.ONBOARDING,
  Routes.LOGIN,
  Routes.REGISTER,
  Routes.CONFIRM,
  Routes.FORGOT_PASSWORD,
  Routes.RESET_PASSWORD,
  Routes.UPDATE_REQUIRED,
  // Blowmusic a déjà son propre mini-lecteur (bottom bar).
  Routes.BLOWMUSIC_HOME,
};

/// Distance entre le bas de l'écran et le mini-lecteur : laisse la place à la
/// bottom bar des modules (ModuleBottomBar). À ajuster si elle change de hauteur.
const double kBmMiniBottomOffset = 76;

class BmMiniPlayerOverlay extends StatelessWidget {
  const BmMiniPlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Lecture réactive : on se réévalue à chaque navigation (c'est aussi ce
      // qui nous fait « découvrir » le contrôleur quand il vient d'être créé).
      final route = currentRouteName.value;
      if (kOverlayHiddenRoutes.contains(route)) return const SizedBox.shrink();

      // Contrôleur absent (jamais ouvert / supprimé) ou seulement déclaré en
      // lazyPut : on ne le force surtout pas à s'instancier.
      if (!Get.isRegistered<BlowMusicController>() ||
          Get.isPrepared<BlowMusicController>()) {
        return const SizedBox.shrink();
      }
      return _BmMiniBar(ctrl: Get.find<BlowMusicController>());
    });
  }
}

class _BmMiniBar extends StatelessWidget {
  const _BmMiniBar({required this.ctrl});
  final BlowMusicController ctrl;

  void _open() {
    if (ctrl.isPlayingLive.value) {
      final i = kBlowMusicTabs.indexWhere((t) => t.icon == 'live');
      ctrl.changeTab(i >= 0 ? i : 1);
      Get.toNamed(Routes.BLOWMUSIC_HOME);
      return;
    }
    // Context situé SOUS le Navigator (celui du builder ne l'est pas).
    final ctx = Get.overlayContext;
    if (ctx != null) openBmPlayer(ctx);
  }

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      final track = ctrl.currentTrack.value;
      final live = ctrl.isPlayingLive.value && ctrl.liveStream.value != null;

      // Lecteur plein écran ouvert (ou vidéo plein écran) : on se masque.
      if (ctrl.playerOpen.value ||
          ctrl.isFullScreen.value ||
          (track == null && !live)) {
        return const SizedBox.shrink();
      }

      final loading = ctrl.playbackState.value == BmPlaybackState.loading;
      final playing = ctrl.isPlaying.value;
      final title =
          track?.title ??
          ctrl.liveStream.value?['title']?.toString() ??
          'Direct';
      final cover =
          track?.coverUrl ?? ctrl.liveStream.value?['cover_url']?.toString();
      final hasCover = cover != null && cover.isNotEmpty;
      final hasQueue = !live && ctrl.queue.length > 1;

      final band = Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _open,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              // Même ambiance que le lecteur plein écran : dégradé sombre
              // teinté de l'accent.
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.lerp(accent, Colors.black, .6)!,
                  const Color(0xFF0B0810),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Row(
                    children: [
                      VinylDisc(
                        size: 46,
                        playing: playing,
                        accent: accent,
                        coverUrl: cover,
                        isCoverUrlAvailable: hasCover,
                        fallbackIcon: live
                            ? Icons.podcasts_rounded
                            : Icons.music_note_rounded,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (live)
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFB7185),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'EN DIRECT',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: .7),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .6,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                track?.artistName ?? 'Blowmusic',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .6),
                                  fontSize: 11.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Lecture / pause (spinner pendant le chargement)
                      GestureDetector(
                        onTap: loading ? null : ctrl.togglePlayPause,
                        child: Container(
                          width: 38,
                          height: 38,
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
                          child: loading
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                      if (hasQueue)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () => ctrl.next(),
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_fullscreen_rounded,
                          color: Colors.white.withValues(alpha: .7),
                          size: 18,
                        ),
                        onPressed: () => _bmCompact.value = true,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: .55),
                          size: 20,
                        ),
                        // Arrête le son ET retire la notification média.
                        onPressed: ctrl.closePlayer,
                      ),
                    ],
                  ),
                ),
                if (!live) _ProgressLine(ctrl: ctrl),
              ],
            ),
          ),
        ),
      );

      final square = _BmSquare(
        ctrl: ctrl,
        title: title,
        cover: cover,
        live: live,
        loading: loading,
        playing: playing,
        accent: accent,
        onOpen: _open,
      );

      return _BmDraggable(band: band, square: square, safeBottom: safeBottom);
    });
  }
}

/// Fine barre de progression : son propre Obx pour ne redessiner QUE elle à
/// chaque tick de lecture (et pas toute la carte).
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.ctrl});
  final BlowMusicController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = ctrl.duration.value.inMilliseconds;
      final p = ctrl.position.value.inMilliseconds;
      final v = d > 0 ? (p / d).clamp(0.0, 1.0).toDouble() : 0.0;
      return LinearProgressIndicator(
        value: v,
        minHeight: 2.5,
        backgroundColor: Colors.white.withValues(alpha: .12),
        valueColor: AlwaysStoppedAnimation(GPTheme.primaryColor),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DÉPLACEMENT + MODE CARRÉ
// ─────────────────────────────────────────────────────────────────────────────
/// true = carré compact ; false = bande pleine largeur.
final ValueNotifier<bool> _bmCompact = ValueNotifier<bool>(false);

/// Coin haut-gauche (null = position par défaut).
final ValueNotifier<Offset?> _bmPos = ValueNotifier<Offset?>(null);

const double _kSq = 92; // côté du carré
const double _kBandH = 72; // hauteur estimée de la bande
const double _kM = 12; // marge

/// Rend le mini-lecteur déplaçable : la bande se déplace verticalement, le
/// carré partout (aimanté au bord gauche/droit au relâchement).
class _BmDraggable extends StatefulWidget {
  const _BmDraggable({
    required this.band,
    required this.square,
    required this.safeBottom,
  });
  final Widget band, square;
  final double safeBottom;

  @override
  State<_BmDraggable> createState() => _BmDraggableState();
}

class _BmDraggableState extends State<_BmDraggable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Offset _from = Offset.zero, _to = Offset.zero;
  bool _lastCompact = _bmCompact.value;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      _bmPos.value = Offset.lerp(
        _from,
        _to,
        Curves.easeOutCubic.transform(_anim.value),
      );
    });
    _bmCompact.addListener(_onModeChange);
  }

  @override
  void dispose() {
    _bmCompact.removeListener(_onModeChange);
    _anim.dispose();
    super.dispose();
  }

  Size get _screen => MediaQuery.of(context).size;
  EdgeInsets get _pad => MediaQuery.of(context).padding;

  Offset _clamp(Offset p, bool compact) {
    final w = compact ? _kSq : _screen.width - 2 * _kM;
    final h = compact ? _kSq : _kBandH;
    final minY = _pad.top + _kM;
    final maxY = math.max(minY, _screen.height - h - _pad.bottom - _kM);
    final minX = _kM;
    final maxX = math.max(minX, _screen.width - w - _kM);
    return Offset(
      compact ? p.dx.clamp(minX, maxX).toDouble() : _kM,
      p.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Offset _default(bool compact) => Offset(
    compact ? _screen.width - _kSq - _kM : _kM,
    _screen.height -
        widget.safeBottom -
        kBmMiniBottomOffset -
        (compact ? _kSq : _kBandH),
  );

  /// Bande ⇄ carré : on garde la hauteur, le carré se range à droite.
  void _onModeChange() {
    if (!mounted || _lastCompact == _bmCompact.value) return;
    _lastCompact = _bmCompact.value;
    final cur = _bmPos.value ?? _default(!_lastCompact);
    _anim.stop();
    _bmPos.value = _clamp(
      Offset(_lastCompact ? _screen.width - _kSq - _kM : _kM, cur.dy),
      _lastCompact,
    );
  }

  void _onUpdate(DragUpdateDetails d, bool compact) {
    if (_anim.isAnimating) _anim.stop();
    final p = _bmPos.value ?? _default(compact);
    _bmPos.value = _clamp(
      Offset(p.dx + (compact ? d.delta.dx : 0), p.dy + d.delta.dy),
      compact,
    );
  }

  void _onEnd(bool compact) {
    if (!compact) return;
    final p = _bmPos.value ?? _default(true);
    final snapX = p.dx + _kSq / 2 < _screen.width / 2
        ? _kM
        : _screen.width - _kSq - _kM;
    _from = p;
    _to = Offset(snapX, p.dy);
    _anim
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _bmCompact,
      builder: (_, compact, __) => ValueListenableBuilder<Offset?>(
        valueListenable: _bmPos,
        // Le contenu n'est pas reconstruit à chaque pixel de déplacement.
        child: RepaintBoundary(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(compact),
              child: compact ? widget.square : widget.band,
            ),
          ),
        ),
        builder: (_, pos, child) {
          final p = _clamp(pos ?? _default(compact), compact);
          return Positioned(
            left: p.dx,
            top: p.dy,
            width: compact ? _kSq : _screen.width - 2 * _kM,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (d) => _onUpdate(d, compact),
              onPanEnd: (_) => _onEnd(compact),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Mode carré : disque + lecture/pause, toucher = repasser en bande.
class _BmSquare extends StatelessWidget {
  const _BmSquare({
    required this.ctrl,
    required this.title,
    required this.cover,
    required this.live,
    required this.loading,
    required this.playing,
    required this.accent,
    required this.onOpen,
  });
  final BlowMusicController ctrl;
  final String title;
  final String? cover;
  final bool live, loading, playing;
  final Color accent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => _bmCompact.value = false,
        child: Container(
          height: _kSq,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, Colors.black, .55)!,
                const Color(0xFF0B0810),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: VinylDisc(
                  size: 58,
                  playing: playing,
                  accent: accent,
                  coverUrl: cover,
                  isCoverUrlAvailable: cover != null && cover!.isNotEmpty,
                  fallbackIcon: live
                      ? Icons.podcasts_rounded
                      : Icons.music_note_rounded,
                ),
              ),
              if (live)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB7185),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: ctrl.closePlayer,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: .6),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: GestureDetector(
                  onTap: loading ? null : ctrl.togglePlayPause,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: GestureDetector(
                  onTap: onOpen,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
