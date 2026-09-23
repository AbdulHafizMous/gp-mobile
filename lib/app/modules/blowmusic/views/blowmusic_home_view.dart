// lib/app/modules/blowmusic/views/blowmusic_home_view.dart
//
// Coquille BlowMusic : couleur d'accent rouge (GPTheme.primaryColor, comme
// demandé — même rouge que le volet Espaces de Grand Public), drawer partagé
// (ModuleDrawer), 4 onglets (Accueil, Live, Bibliothèque, Playlists) + un
// mini-lecteur persistant en bas.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/module_drawer.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/blowmusic_controller.dart';

class BlowMusicHomeView extends GetView<BlowMusicController> {
  const BlowMusicHomeView({super.key});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'home': return Icons.home_rounded;
      case 'live': return Icons.podcasts_rounded;
      case 'library': return Icons.library_music_rounded;
      case 'playlist': return Icons.playlist_play_rounded;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B12),
      drawer: ModuleDrawer(accentColor: accent, moduleName: 'Blow Music'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0B12),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Blow Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        switch (controller.currentTab.value) {
          case 1:
            return _LiveTab(accent: accent);
          case 2:
            return _LibraryTab(accent: accent);
          case 3:
            return const _PlaylistsTab();
          default:
            return _HomeTab(accent: accent);
        }
      }),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MiniPlayer(),
          Obx(() => BottomNavigationBar(
            backgroundColor: const Color(0xFF0E0B12),
            selectedItemColor: accent,
            unselectedItemColor: Colors.white38,
            currentIndex: controller.currentTab.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            items: kBlowMusicTabs.map((t) => BottomNavigationBarItem(icon: Icon(_iconFor(t.icon)), label: t.label)).toList(),
          )),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Color accent;
  const _HomeTab({required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return RefreshIndicator(
      onRefresh: ctrl.loadHome,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('En ce moment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Obx(() => ctrl.latestTracks.isEmpty
              ? Text('Aucun titre pour le moment.', style: TextStyle(color: Colors.white38))
              : Column(children: ctrl.latestTracks.map((t) => _TrackTile(track: t, accent: accent)).toList())),
          const SizedBox(height: 20),
          const Text('Les plus écoutés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Obx(() => Column(children: ctrl.mostPlayed.map((t) => _TrackTile(track: t, accent: accent)).toList())),
        ],
      ),
    );
  }
}

class _LiveTab extends StatelessWidget {
  final Color accent;
  const _LiveTab({required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return Obx(() {
      final live = ctrl.liveStream.value;
      if (live == null) {
        return Center(child: Text('Pas de direct en cours.', style: TextStyle(color: Colors.white38)));
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.podcasts_rounded, color: accent, size: 64),
            const SizedBox(height: 12),
            Text(live['title']?.toString() ?? 'Live', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (live['now_playing_title'] != null)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('En cours : ${live['now_playing_title']}', style: TextStyle(color: Colors.white54))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: ctrl.playLive,
              style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Écouter le direct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    });
  }
}

class _LibraryTab extends StatelessWidget {
  final Color accent;
  const _LibraryTab({required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return Obx(() => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...ctrl.latestTracks.map((t) => _TrackTile(track: t, accent: accent)),
        ...ctrl.mostPlayed.map((t) => _TrackTile(track: t, accent: accent)),
      ],
    ));
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Vos playlists apparaîtront ici.', style: TextStyle(color: Colors.white38)));
  }
}

class _TrackTile extends StatelessWidget {
  final BmTrack track;
  final Color accent;
  const _TrackTile({required this.track, required this.accent});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: accent.withOpacity(0.2), child: Icon(Icons.music_note_rounded, color: accent, size: 18)),
      title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: track.artistName != null ? Text(track.artistName!, style: TextStyle(color: Colors.white54, fontSize: 12)) : null,
      trailing: Icon(Icons.play_circle_fill_rounded, color: accent),
      onTap: () => ctrl.playTrack(track),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();
    return Obx(() {
      final track = ctrl.currentTrack.value;
      if (track == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: GPTheme.primaryColor.withOpacity(0.15),
        child: Row(
          children: [
            Icon(Icons.music_note_rounded, color: GPTheme.primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(track.title, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: Icon(ctrl.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
              onPressed: ctrl.togglePlayPause,
            ),
          ],
        ),
      );
    });
  }
}
