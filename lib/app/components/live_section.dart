// lib/app/components/live_section.dart
//
// Section « Live » d'une catégorie Grandpublic (ex. EVENTS). Source HLS
// (OBS via notre serveur de streaming) ou YouTube. Affichée uniquement si la
// catégorie a un live actif (voir SpaceView). Options : lecture/pause, son,
// plein écran, recharger.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'live_fullscreen_page.dart';

class LiveSection extends StatefulWidget {
  final Map<String, dynamic> live;
  const LiveSection({super.key, required this.live});

  @override
  State<LiveSection> createState() => _LiveSectionState();
}

class _LiveSectionState extends State<LiveSection> {
  VideoPlayerController? _vc;
  YoutubePlayerController? _yt;
  bool _loading = false, _error = false, _started = false;

  bool get _isYoutube => widget.live['provider'] == 'youtube';
  String get _title => widget.live['title']?.toString() ?? 'Live';

  @override
  void initState() {
    super.initState();
    if (_isYoutube) {
      final id = widget.live['youtube_id']?.toString() ?? '';
      _yt = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          isLive: true,
          forceHD: false,
          enableCaption: false,
        ),
      );
    }
  }

  Future<void> _startHls() async {
    final url = widget.live['stream_url']?.toString() ?? '';
    if (url.isEmpty) return;
    setState(() {
      _loading = true;
      _error = false;
      _started = true;
    });
    try {
      await _vc?.dispose();
      final c = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      await c.initialize();
      c.addListener(() {
        if (mounted) setState(() {});
      });
      await c.play();
      _vc = c;
    } catch (_) {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _vc?.dispose();
    _yt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE11D48), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withOpacity(.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: isDark ? const Color(0xFF101014) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isYoutube ? _youtubePlayer() : _hlsPlayer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    const LiveBadge(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if ((widget.live['description'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.live['description'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _youtubePlayer() {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _yt!,
        showVideoProgressIndicator: false,
        progressIndicatorColor: const Color(0xFFE11D48),
      ),
      builder: (_, player) => player,
    );
  }

  Widget _hlsPlayer() {
    final thumb = widget.live['thumbnail_url']?.toString();
    final c = _vc;
    final ready = c != null && c.value.isInitialized;
    final ratio = ready && c.value.aspectRatio > 0
        ? c.value.aspectRatio
        : 16 / 9;

    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            Container(color: Colors.black, child: VideoPlayer(c))
          else ...[
            Container(color: Colors.black),
            if (thumb != null && thumb.isNotEmpty)
              Image.network(
                thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ],
          if (_loading || (ready && c.value.isBuffering))
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_error)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Flux momentanément indisponible',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  TextButton.icon(
                    onPressed: _startHls,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (!_started)
            Center(
              child: GestureDetector(
                onTap: _startHls,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE11D48),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          if (ready)
            Positioned(
              left: 6,
              right: 6,
              bottom: 4,
              child: Row(
                children: [
                  _ctl(
                    c.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    () => c.value.isPlaying ? c.pause() : c.play(),
                  ),
                  _ctl(
                    c.value.volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    () => c.setVolume(c.value.volume == 0 ? 1 : 0),
                  ),
                  _ctl(Icons.refresh_rounded, _startHls),
                  const Spacer(),
                  _ctl(
                    Icons.fullscreen_rounded,
                    () => Get.to(
                      () => LiveFullscreenPage(controller: c, title: _title),
                      transition: Transition.fade,
                      fullscreenDialog: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ctl(IconData i, VoidCallback f) => IconButton(
    visualDensity: VisualDensity.compact,
    icon: Icon(
      i,
      color: Colors.white,
      size: 24,
      shadows: const [Shadow(blurRadius: 6, color: Colors.black87)],
    ),
    onPressed: f,
  );
}
