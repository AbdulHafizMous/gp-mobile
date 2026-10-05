import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/components/live_fullscreen_page.dart';
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
      drawer: ModuleDrawer(
        accentColor: accent,
        moduleName: 'Blow Music',
        moduleLogo: LOGO_BLOWMUSIC,
        variableItems: [
          ModuleDrawerNavItem(title: 'Accueil', icon: Icons.home_rounded, onTap: () => controller.changeTab(0)),
          ModuleDrawerNavItem(title: 'Live', icon: Icons.podcasts_rounded, onTap: () => controller.changeTab(1)),
          ModuleDrawerNavItem(title: 'Biblio', icon: Icons.library_music_rounded, onTap: () => controller.changeTab(2)),
          ModuleDrawerNavItem(title: 'Playlists', icon: Icons.playlist_play_rounded, onTap: () => controller.changeTab(3)),
        ],
      ),
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
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(recent[i]['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ),
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
        return RefreshIndicator(
          onRefresh: ctrl.refreshLive,
          child: ListView(children: const [
            SizedBox(height: 120),
            EmptyStateWidget(icon: Icons.podcasts_outlined, message: 'Pas de direct en cours pour le moment.'),
          ]),
        );
      }

      final state = ctrl.playbackState.value;
      final isThis = ctrl.isPlayingLive.value;
      final v = ctrl.videoPlayerController;
      final isAudio = live['media_type'] == 'audio';
      final isRadio = live['kind'] == 'radio';
      final playing = isThis && ctrl.isPlaying.value;
      final showVideo = isThis && v != null && v.value.isInitialized && ctrl.isVideo.value;

      return RefreshIndicator(
        onRefresh: ctrl.refreshLive,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // ── Scène : vidéo ou visuel audio animé ──────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: showVideo
                  ? _VideoStage(key: const ValueKey('v'), ctrl: ctrl, v: v)
                  : _AudioStage(key: ValueKey('a${live['id']}'), accent: accent, playing: playing, radio: isRadio, audio: isAudio),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const LiveBadge(),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: accent.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isRadio ? Icons.radio_rounded : (isAudio ? Icons.headphones_rounded : Icons.videocam_rounded), size: 14, color: accent),
                  const SizedBox(width: 4),
                  Text(isRadio ? 'Radio' : (isAudio ? 'Audio' : 'Vidéo'), style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Text(live['title']?.toString() ?? 'Direct',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            if ((live['description'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(live['description'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withOpacity(.6), fontSize: 13), textAlign: TextAlign.center),
              ),
            if (live['now_playing_title'] != null && live['now_playing_title'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.music_note_rounded, size: 16, color: accent),
                  const SizedBox(width: 4),
                  Flexible(child: Text(live['now_playing_title'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withOpacity(.75), fontSize: 14))),
                ]),
              ),
            const SizedBox(height: 22),
            if (isThis && state == BmPlaybackState.loading)
              const CircularProgressIndicator()
            else if (isThis && state == BmPlaybackState.error)
              Column(children: [
                Text('Impossible de lire ce flux pour le moment.', style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                const SizedBox(height: 10),
                ElevatedButton.icon(onPressed: ctrl.playLive, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
              ])
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(colors: [accent, Color.lerp(accent, const Color(0xFF7C3AED), .55)!]),
                  boxShadow: [BoxShadow(color: accent.withOpacity(.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton.icon(
                  onPressed: playing ? ctrl.togglePlayPause : ctrl.playLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
                  label: Text(playing ? 'Pause' : (isThis ? 'Reprendre' : 'Écouter le direct'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _VideoStage extends StatelessWidget {
  final BlowMusicController ctrl;
  final VideoPlayerController v;
  const _VideoStage({super.key, required this.ctrl, required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: v.value.aspectRatio > 0 ? v.value.aspectRatio : 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: Colors.black, child: VideoPlayer(v)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Color(0xAA000000), Colors.transparent]),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 2,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 30, shadows: [Shadow(blurRadius: 6, color: Colors.black87)]),
                onPressed: () => ctrl.toggleFullScreen(context),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Visuel audio : disque dégradé + ondes animées (équaliseur) pendant la lecture.
class _AudioStage extends StatefulWidget {
  final Color accent;
  final bool playing, radio, audio;
  const _AudioStage({super.key, required this.accent, required this.playing, required this.radio, required this.audio});

  @override
  State<_AudioStage> createState() => _AudioStageState();
}

class _AudioStageState extends State<_AudioStage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    return SizedBox(
      height: 220,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          for (var i = 0; i < 3; i++)
            Builder(builder: (_) {
              final t = widget.playing ? ((_c.value + i / 3) % 1.0) : 0.0;
              return Opacity(
                opacity: widget.playing ? (1 - t) * .35 : .12,
                child: Container(
                  width: 120 + t * 100,
                  height: 120 + t * 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: a, width: 2)),
                ),
              );
            }),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [a, const Color(0xFF7C3AED), const Color(0xFFE11D48)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: a.withOpacity(.45), blurRadius: 28, spreadRadius: 2)],
            ),
            child: Transform.rotate(
              angle: widget.playing ? _c.value * 6.283 * .15 : 0,
              child: Icon(widget.radio ? Icons.radio_rounded : (widget.audio ? Icons.graphic_eq_rounded : Icons.podcasts_rounded), color: Colors.white, size: 62),
            ),
          ),
          // Équaliseur
          Positioned(
            bottom: 6,
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 14; i++)
                Container(
                  width: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: widget.playing ? 6 + 26 * (0.5 + 0.5 * math.sin((_c.value * 6.283 * 2) + i * .9)).abs() : 6,
                  decoration: BoxDecoration(color: a.withOpacity(.8), borderRadius: BorderRadius.circular(3)),
                ),
            ]),
          ),
        ]),
      ),
    );
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

  Widget _coverFallback() => Container(
        color: accent.withOpacity(0.15),
        child: Icon(Icons.music_note_rounded, color: accent, size: 22),
      );

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 48,
          child: (track.coverUrl != null && track.coverUrl!.isNotEmpty)
              ? Image.network(
                  track.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverFallback(),
                )
              : _coverFallback(),
        ),
      ),
      title: Text(track.title, style: TextStyle(color: fg, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: track.artistName != null
          ? Text(track.artistName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withOpacity(0.5), fontSize: 12))
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