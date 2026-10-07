// lib/app/components/live_fullscreen_page.dart
//
// Plein écran VIDÉO (live HLS, Blowmusic & Grandpublic). Corrige l'ancien
// rendu « une partie seulement » : on force la taille native de la vidéo dans
// un FittedBox(contain) qui remplit TOUT l'écran (SizedBox.expand), en
// paysage immersif, avec contrôles qui se masquent automatiquement.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class LiveFullscreenPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final bool isLive;
  const LiveFullscreenPage({
    super.key,
    required this.controller,
    required this.title,
    this.isLive = true,
  });

  @override
  State<LiveFullscreenPage> createState() => _LiveFullscreenPageState();
}

class _LiveFullscreenPageState extends State<LiveFullscreenPage> {
  bool _controls = true;
  Timer? _hide;

  VideoPlayerController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    c.addListener(_tick);
    _scheduleHide();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && c.value.isPlaying) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    if (_controls) _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    c.removeListener(_tick);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = c.value.isInitialized && c.value.size.width > 0
        ? c.value.size
        : const Size(1920, 1080);
    final playing = c.value.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vidéo : remplit tout l'écran sans déformation
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
            if (c.value.isBuffering)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            AnimatedOpacity(
              opacity: _controls ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_controls,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xCC000000),
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xCC000000),
                          ],
                          stops: [0, .28, .72, 1],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen_exit_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.isLive) const _LiveBadge(),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          playing ? c.pause() : c.play();
                          _scheduleHide();
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54),
                          ),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 16,
                      child: SafeArea(
                        child: IconButton(
                          icon: Icon(
                            c.value.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            c.setVolume(c.value.volume == 0 ? 1 : 0);
                            _scheduleHide();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille « EN DIRECT » pulsante.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: .35, end: 1.0).animate(_a),
            child: const Icon(Icons.circle, size: 8, color: Colors.white),
          ),
          const SizedBox(width: 5),
          const Text(
            'EN DIRECT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});
  @override
  Widget build(BuildContext context) => const _LiveBadge();
}
