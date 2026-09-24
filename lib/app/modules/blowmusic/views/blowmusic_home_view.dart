import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:grand_public_v2/app/components/empty_state_widget.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/recent_history_service.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/blowmusic_controller.dart';

class BlowMusicHomeView extends GetView<BlowMusicController> {
  const BlowMusicHomeView({super.key});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'home':
        return Icons.home_rounded;
      case 'live':
        return Icons.podcasts_rounded;
      case 'library':
        return Icons.library_music_rounded;
      case 'playlist':
        return Icons.playlist_play_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0B12) : const Color(0xFFF7F5F8);
    final fg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      drawer: ModuleDrawer(accentColor: accent, moduleName: 'Blow Music'),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              LOGO_BLOWMUSIC_NAV,
              width: 30,
              height: 30,
              errorBuilder: (_, __, ___) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Text('Blow Music', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        switch (controller.currentTab.value) {
          case 1:
            return _LiveTab(accent: accent, fg: fg);
          case 2:
            return _LibraryTab(accent: accent, fg: fg);
          case 3:
            return _PlaylistsTab(fg: fg);
          default:
            return _HomeTab(accent: accent, fg: fg);
        }
      }),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MiniPlayer(),
          Obx(() => BottomNavigationBar(
                backgroundColor: bg,
                selectedItemColor: accent,
                unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
                currentIndex: controller.currentTab.value,
                onTap: controller.changeTab,
                type: BottomNavigationBarType.fixed,
                items: kBlowMusicTabs
                    .map((t) => BottomNavigationBarItem(icon: Icon(_iconFor(t.icon)), label: t.label))
                    .toList(),
              )),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: ACCUEIL
// -----------------------------------------------------------------------------
class _HomeTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _HomeTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    final recent = RecentHistoryService.recentTracks;

    return RefreshIndicator(
      onRefresh: ctrl.loadHome,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ctrl.hasError.value)
            EmptyStateWidget(
              icon: Icons.wifi_off_rounded,
              message: 'Connexion impossible. Tirez pour réessayer.',
              color: accent,
            ),
          if (recent.isNotEmpty) ...[
            Text('Repris récemment', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Chip(
                  label: Text(recent[i]['title'] ?? '', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('En ce moment', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Obx(() => ctrl.latestTracks.isEmpty
              ? const EmptyStateWidget(icon: Icons.music_off_rounded, message: 'Aucun morceau disponible.')
              : Column(children: ctrl.latestTracks.map((t) => _TrackTile(track: t, accent: accent, fg: fg)).toList())),
          const SizedBox(height: 20),
          Text('Les plus écoutés', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Obx(() => ctrl.mostPlayed.isEmpty
              ? const EmptyStateWidget(icon: Icons.trending_up_rounded, message: 'Pas de classement disponible.')
              : Column(children: ctrl.mostPlayed.map((t) => _TrackTile(track: t, accent: accent, fg: fg)).toList())),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: LIVE (Gestion Streaming Audio & Vidéo OBS/HLS)
// -----------------------------------------------------------------------------
class _LiveTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _LiveTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();

    return Obx(() {
      final live = ctrl.liveStream.value;
      if (live == null) {
        return const EmptyStateWidget(
            icon: Icons.podcasts_outlined, message: 'Pas de direct en cours pour le moment.');
      }

      final state = ctrl.playbackState.value;
      final isThisLivePlaying = ctrl.isPlayingLive.value;
      final vController = ctrl.videoPlayerController;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Affichage du Lecteur Vidéo si le flux est actif et contient de la vidéo
            if (isThisLivePlaying &&
                vController != null &&
                vController.value.isInitialized &&
                ctrl.isVideo.value)
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: vController.value.aspectRatio,
                        child: VideoPlayer(vController),
                      ),
                      // Contrôles superposés sur la vidéo
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 28),
                          onPressed: () => ctrl.toggleFullScreen(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Fallback visuel Audio / Podcast
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.podcasts_rounded, color: accent, size: 64),
              ),

            const SizedBox(height: 16),
            Text(
              live['title']?.toString() ?? 'Direct',
              style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (live['now_playing_title'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'En cours : ${live['now_playing_title']}',
                  style: TextStyle(color: fg.withOpacity(0.6), fontSize: 14),
                ),
              ),

            const SizedBox(height: 24),

            // État des boutons de contrôles
            if (isThisLivePlaying && state == BmPlaybackState.loading)
              const CircularProgressIndicator()
            else if (isThisLivePlaying && state == BmPlaybackState.error)
              Column(
                children: [
                  Text('Impossible de lire ce flux direct pour le moment.',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: ctrl.playLive,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: (isThisLivePlaying && ctrl.isPlaying.value)
                    ? ctrl.togglePlayPause
                    : ctrl.playLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: Icon(
                  (isThisLivePlaying && ctrl.isPlaying.value)
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                label: Text(
                  (isThisLivePlaying && ctrl.isPlaying.value) ? 'Mettre en pause' : 'Lancer le Direct',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// TAB 3 & 4: BIBLIOTHÈQUE & PLAYLISTS
// -----------------------------------------------------------------------------
class _LibraryTab extends StatelessWidget {
  final Color accent;
  final Color fg;
  const _LibraryTab({required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return Obx(() {
      final all = [...ctrl.latestTracks, ...ctrl.mostPlayed];
      if (all.isEmpty) {
        return const EmptyStateWidget(
            icon: Icons.library_music_outlined, message: 'Votre bibliothèque est vide.');
      }
      return ListView(
          padding: const EdgeInsets.all(16),
          children: all.map((t) => _TrackTile(track: t, accent: accent, fg: fg)).toList());
    });
  }
}

class _PlaylistsTab extends StatelessWidget {
  final Color fg;
  const _PlaylistsTab({required this.fg});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
        icon: Icons.playlist_add_rounded, message: 'Vous n\'avez pas encore créé de playlist.');
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS : TILE MORCEAU
// -----------------------------------------------------------------------------
class _TrackTile extends StatelessWidget {
  final BmTrack track;
  final Color accent;
  final Color fg;
  const _TrackTile({required this.track, required this.accent, required this.fg});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: accent.withOpacity(0.15),
        child: Icon(Icons.music_note_rounded, color: accent, size: 20),
      ),
      title: Text(track.title, style: TextStyle(color: fg, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: track.artistName != null
          ? Text(track.artistName!, style: TextStyle(color: fg.withOpacity(0.5), fontSize: 12))
          : null,
      trailing: Icon(Icons.play_circle_fill_rounded, color: accent, size: 32),
      onTap: () => ctrl.playTrack(track),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANTS : MINI PLAYER AVEC BARRE DE PROGRESSION
// -----------------------------------------------------------------------------
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();

    return Obx(() {
      final track = ctrl.currentTrack.value;
      final showLive = ctrl.isPlayingLive.value && ctrl.liveStream.value != null;

      if (track == null && !showLive) return const SizedBox.shrink();

      final label = track?.title ?? ctrl.liveStream.value?['title']?.toString() ?? 'Direct';
      final subtitle = track?.artistName ?? (showLive ? 'En Direct' : '');

      return Container(
        decoration: BoxDecoration(
          color: GPTheme.primaryColor.withOpacity(0.12),
          border: Border(top: BorderSide(color: GPTheme.primaryColor.withOpacity(0.2))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de progression si c'est un morceau enregistré (non-Live)
            if (!showLive && ctrl.duration.value.inSeconds > 0)
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                  activeTrackColor: GPTheme.primaryColor,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  thumbColor: GPTheme.primaryColor,
                ),
                child: Slider(
                  value: ctrl.position.value.inSeconds.toDouble().clamp(
                        0.0,
                        ctrl.duration.value.inSeconds.toDouble(),
                      ),
                  max: ctrl.duration.value.inSeconds.toDouble(),
                  onChanged: (val) => ctrl.seekTo(Duration(seconds: val.toInt())),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(showLive ? Icons.podcasts_rounded : Icons.music_note_rounded,
                      color: GPTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (subtitle.isNotEmpty)
                          Text(subtitle,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (ctrl.playbackState.value == BmPlaybackState.loading)
                    const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      icon: Icon(
                        ctrl.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 32,
                        color: GPTheme.primaryColor,
                      ),
                      onPressed: ctrl.togglePlayPause,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}