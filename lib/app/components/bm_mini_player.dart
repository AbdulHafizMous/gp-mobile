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
          track?.title ?? ctrl.liveStream.value?['title']?.toString() ?? 'Direct';
      final cover =
          track?.coverUrl ?? ctrl.liveStream.value?['cover_url']?.toString();
      final hasCover = cover != null && cover.isNotEmpty;
      final hasQueue = !live && ctrl.queue.length > 1;

      return Positioned(
        left: 12,
        right: 12,
        bottom: safeBottom + kBmMiniBottomOffset,
        child: Material(
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
        ),
      );
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
