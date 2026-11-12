import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/empty_state_widget.dart';
import 'package:video_player/video_player.dart';

import 'package:grand_public_v2/app/components/ad_native_card.dart';
import '../controllers/blowmusic_controller.dart';

/// Onglet « Émissions » : groupes de vidéos (comme les playlists), puis les épisodes
/// d'une émission avec l'affichage vidéo des chaînes. Ni likes ni commentaires.
class BmShowsTab extends StatefulWidget {
  final Color accent, fg;
  const BmShowsTab({super.key, required this.accent, required this.fg});

  @override
  State<BmShowsTab> createState() => _BmShowsTabState();
}

class _BmShowsTabState extends State<BmShowsTab> {
  BmShow? _open;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BlowMusicController>();
    return _open == null ? _list(c) : _episodes(c, _open!);
  }

  Widget _list(BlowMusicController c) {
    return Obx(() {
      final loading = c.showsLoading.value;
      final items = c.shows.toList();
      if (loading && items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: c.loadShows,
        child: items.isEmpty
            ? ListView(children: const [
                SizedBox(height: 120),
                EmptyStateWidget(icon: Icons.live_tv_rounded, message: 'Les émissions arrivent bientôt.'),
              ])
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .82),
                itemCount: items.length,
                itemBuilder: (_, i) => _ShowCard(
                  show: items[i], accent: widget.accent, fg: widget.fg,
                  onTap: () {
                    c.loadEpisodes(items[i].id);
                    setState(() => _open = items[i]);
                  },
                ),
              ),
      );
    });
  }

  Widget _episodes(BlowMusicController c, BmShow show) {
    final fg = widget.fg;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
        child: Row(children: [
          IconButton(icon: Icon(Icons.arrow_back_rounded, color: fg), onPressed: () => setState(() => _open = null)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
              if (show.schedule.isNotEmpty)
                Text(show.schedule, style: TextStyle(color: fg.withOpacity(.6), fontSize: 12)),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: Obx(() {
          if (c.episodesLoading.value) return const Center(child: CircularProgressIndicator());
          final eps = c.episodes.toList();
          if (eps.isEmpty) {
            return const EmptyStateWidget(icon: Icons.video_library_outlined, message: 'Aucun épisode pour le moment.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: eps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => Column(children: [
              if (i > 0 && i % 4 == 0) const AdNativeCard(screen: 'blowmusic_shows', margin: EdgeInsets.only(bottom: 16)),
              _EpisodeCard(ep: eps[i], accent: widget.accent, fg: fg, onTap: () {
                c.trackEpisodeView(eps[i]);
                Get.to(() => BmEpisodePage(episode: eps[i], showTitle: show.title));
              }),
            ]),
          );
        }),
      ),
    ]);
  }
}

class _ShowCard extends StatelessWidget {
  final BmShow show;
  final Color accent, fg;
  final VoidCallback onTap;
  const _ShowCard({required this.show, required this.accent, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(fit: StackFit.expand, children: [
              show.coverUrl != null && show.coverUrl!.isNotEmpty
                  ? Image.network(show.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                  : _ph(),
              Positioned(
                right: 8, bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text('${show.episodes} ép.', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
        if (show.schedule.isNotEmpty)
          Text(show.schedule, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withOpacity(.6), fontSize: 11)),
      ]),
    );
  }

  Widget _ph() => Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accent.withOpacity(.55)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: const Icon(Icons.live_tv_rounded, color: Colors.white70, size: 40),
      );
}

class _EpisodeCard extends StatelessWidget {
  final BmEpisode ep;
  final Color accent, fg;
  final VoidCallback onTap;
  const _EpisodeCard({required this.ep, required this.accent, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(fit: StackFit.expand, children: [
              ep.thumbnailUrl != null && ep.thumbnailUrl!.isNotEmpty
                  ? Image.network(ep.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black87))
                  : Container(color: Colors.black87),
              Center(
                child: Container(
                  width: 54, height: 54,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(ep.isAudio ? Icons.headphones_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(ep.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
        if (ep.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(ep.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg.withOpacity(.6), fontSize: 12)),
          ),
      ]),
    );
  }
}

/// Lecteur d'épisode (vidéo ou audio) : plein écran possible via Chewie, aucun like ni commentaire.
class BmEpisodePage extends StatefulWidget {
  final BmEpisode episode;
  final String showTitle;
  const BmEpisodePage({super.key, required this.episode, required this.showTitle});

  @override
  State<BmEpisodePage> createState() => _BmEpisodePageState();
}

class _BmEpisodePageState extends State<BmEpisodePage> {
  VideoPlayerController? _v;
  ChewieController? _c;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Un seul son à la fois : on coupe le lecteur Blowmusic.
    final bm = Get.isRegistered<BlowMusicController>() ? Get.find<BlowMusicController>() : null;
    if (bm != null && bm.isPlaying.value) bm.togglePlayPause();
    _init();
  }

  Future<void> _init() async {
    final url = widget.episode.playUrl;
    if (url == null || url.isEmpty) {
      setState(() => _error = true);
      return;
    }
    try {
      final v = VideoPlayerController.networkUrl(Uri.parse(url));
      await v.initialize();
      _v = v;
      _c = ChewieController(
        videoPlayerController: v,
        autoPlay: true,
        aspectRatio: widget.episode.isAudio ? 16 / 9 : v.value.aspectRatio,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(playedColor: Colors.white, handleColor: Colors.white),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    _v?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.showTitle, style: const TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: Column(children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _error
                ? const Center(child: Text('Lecture impossible.', style: TextStyle(color: Colors.white70)))
                : _c == null
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Chewie(controller: _c!),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.episode.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                if (widget.episode.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.episode.description, style: const TextStyle(color: Colors.white70, height: 1.4)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
