import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:video_player/video_player.dart';

/// Lecteur d'un média « direct uniquement » : web radio (flux audio, même rendu que le live Blowmusic)
/// ou web TV (flux vidéo HLS). Aucun catalogue : on écoute / regarde le direct.
class ChannelLivePage extends StatefulWidget {
  final ChannelModel channel;
  const ChannelLivePage({super.key, required this.channel});

  @override
  State<ChannelLivePage> createState() => _ChannelLivePageState();
}

class _ChannelLivePageState extends State<ChannelLivePage> with SingleTickerProviderStateMixin {
  VideoPlayerController? _v;
  late final AnimationController _eq = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  bool _loading = true, _error = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await _v?.dispose();
      final v = VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl!), videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false));
      await v.initialize();
      await v.play();
      v.addListener(() {
        if (mounted) setState(() {});
      });
      _v = v;
    } catch (_) {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _eq.dispose();
    _v?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.channel;
    final playing = _v?.value.isPlaying ?? false;
    final showVideo = !ch.audioOnly && _v != null && _v!.value.isInitialized;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0B12),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(ch.kindLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (showVideo)
                ClipRRect(borderRadius: BorderRadius.circular(18), child: AspectRatio(aspectRatio: _v!.value.aspectRatio, child: VideoPlayer(_v!)))
              else
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(alignment: Alignment.center, children: [
                    AnimatedBuilder(
                      animation: _eq,
                      builder: (_, __) => CustomPaint(size: const Size(220, 220), painter: _Rings(_eq.value, playing)),
                    ),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 3), color: Colors.white10),
                      clipBehavior: Clip.antiAlias,
                      child: ch.logoUrl != null ? Image.network(ch.logoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.radio_rounded, color: Colors.white, size: 54)) : const Icon(Icons.radio_rounded, color: Colors.white, size: 54),
                    ),
                  ]),
                ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(20)),
                child: const Text('EN DIRECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              Text(ch.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              if (ch.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(ch.description, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, height: 1.4)),
                ),
              const SizedBox(height: 28),
              if (_loading)
                const CircularProgressIndicator(color: Colors.white)
              else if (_error)
                Column(children: [
                  const Text('Flux indisponible pour le moment.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _start, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), child: const Text('Réessayer')),
                ])
              else
                GestureDetector(
                  onTap: () => playing ? _v!.pause() : _v!.play(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 42, color: Colors.black),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Rings extends CustomPainter {
  final double t;
  final bool on;
  _Rings(this.t, this.on);

  @override
  void paint(Canvas canvas, Size s) {
    if (!on) return;
    final c = s.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      canvas.drawCircle(c, 65 + 45 * p, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: .35 * (1 - p)));
    }
    // petites barres d'égaliseur autour du disque
    for (var i = 0; i < 24; i++) {
      final a = i / 24 * 2 * math.pi;
      final h = 6 + 10 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 2 + i));
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * 72, c + Offset(math.cos(a), math.sin(a)) * (72 + h), Paint()..color = Colors.white54..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _Rings o) => true;
}
