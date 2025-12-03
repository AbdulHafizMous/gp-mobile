// Clean, restored VidDetail that accepts a Video from the parent view.
// Simpler, robust VidDetail implementation to avoid parser issues.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/comment.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/routes/app_pages.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VidDetail extends StatefulWidget {
  const VidDetail({super.key, required this.video});

  final Video video;

  @override
  State<VidDetail> createState() => _VidDetailState();
}

class _VidDetailState extends State<VidDetail> {
  final controller = Get.put(HomeController());
  YoutubePlayerController? _ytController;
  Timer? _watchdog;
  bool _playerStarted = false;
  bool _playerError = false;
  int _retry = 0;

  @override
  void initState() {
    super.initState();
    final id = _normalizeId(widget.video.youtubeId);
    if (id.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(autoPlay: true),
      );
      _ytController?.addListener(_listener);
      _startWatchdog();
    } else {
      // No valid YouTube id: show fallback UI (thumbnail + open external)
      _playerError = true;
    }

    final has = GetStorage().read('has_active_subscriptions') ?? false;
    if (!has && widget.video.id > 0) {
      // Only redirect if we have a valid video and no subscription
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          debugPrint('VidDetail nexus: has_active_subscriptions = $has');
          Get.toNamed(Routes.SOCIAL_PREMIUM);
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      });
    }
  }

  String _normalizeId(String? input) {
    if (input == null) return '';
    try {
      final id = YoutubePlayer.convertUrlToId(input);
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return input.trim();
  }

  void _listener() {
    final v = _ytController?.value;
    if (v == null) return;
    if (v.isPlaying && !_playerStarted) {
      setState(() {
        _playerStarted = true;
        _playerError = false;
      });
      _watchdog?.cancel();
    }
    if (v.hasError) {
      debugPrint('YT error code=${v.errorCode}');
    }
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _playerStarted = false;
    _playerError = false;
    _watchdog = Timer(const Duration(seconds: 5), () {
      if (!_playerStarted) {
        setState(() {
          _playerError = true;
          _retry++;
        });
        if (_retry >= 2) _openExternal();
      }
    });
  }

  Future<void> _openExternal() async {
    final id = _normalizeId(widget.video.youtubeId);
    Uri url;
    if (id.isNotEmpty) {
      url = Uri.parse('https://www.youtube.com/watch?v=$id');
    } else if (widget.video.youtubeId.isNotEmpty) {
      // If the stored value is already a full URL, try it
      try {
        url = Uri.parse(widget.video.youtubeId);
      } catch (_) {
        // fallback to search by title
        final query = Uri.encodeComponent(widget.video.title);
        url = Uri.parse('https://www.youtube.com/results?search_query=$query');
      }
    } else {
      // nothing to open
      return;
    }
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _ytController?.removeListener(_listener);
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    return Scaffold(
      appBar: AppBar(title: Text(video.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_ytController != null && !_playerError) ...[
            YoutubePlayer(controller: _ytController!),
          ] else ...[
            // Fallback UI: thumbnail + open externally
            Card(
              color: Colors.yellow[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Le lecteur n\'a pas pu démarrer.'),
                    const SizedBox(height: 8),
                    if (widget.video.videoThumbnail.isNotEmpty)
                      Image.network(
                        widget.video.videoThumbnail,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _retryPressed,
                          child: const Text('Réessayer'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _openExternal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text(
                            'Ouvrir sur YouTube',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            video.description ?? 'Aucune description',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Partager')),
          const SizedBox(height: 12),
          const Text(
            'Commentaires',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Comment>>(
            future: controller.getVideoComment(video.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snap.hasError) return const Text('Erreur');
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Text('Aucun commentaire');
              }
              final items = snap.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final c = items[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundImage: AssetImage('assets/images/logo.png'),
                    ),
                    title: Text(c.authorName),
                    subtitle: Text(c.content),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _retryPressed() {
    setState(() {
      _playerError = false;
      _playerStarted = false;
    });
    try {
      _ytController?.load(_normalizeId(widget.video.youtubeId));
      _startWatchdog();
    } catch (e) {
      debugPrint('Retry load failed: $e');
    }
  }
}
