import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:grand_public_v2/app/components/vinyl_disc.dart';
// import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/blowmusic_controller.dart';
import 'bm_playlist_page.dart';

/// Ouvre le lecteur plein écran avec une transition « le mini-lecteur
/// s'étend » (glissement vers le haut + fondu).
Future<void> openBmPlayer(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => const BmPlayerPage(),
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(
          parent: a,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(c),
          child: FadeTransition(opacity: c, child: child),
        );
      },
    ),
  );
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '${d.inMinutes}:$s';
}

class BmPlayerPage extends StatefulWidget {
  const BmPlayerPage({super.key});

  @override
  State<BmPlayerPage> createState() => _BmPlayerPageState();
}

class _BmPlayerPageState extends State<BmPlayerPage>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.find<BlowMusicController>();
  late final AnimationController _eq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  double? _drag;

  @override
  void dispose() {
    _eq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;
    final w = MediaQuery.of(context).size;
    final disc = math.min(w.width * .74, w.height * .36);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0810),
      body: Obx(() {
        final t = ctrl.currentTrack.value;
        if (t == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop())
              Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        final playing = ctrl.isPlaying.value;
        final loading = ctrl.playbackState.value == BmPlaybackState.loading;
        final hasCover = t.coverUrl != null && t.coverUrl!.isNotEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Fond : dégradé + pochette floutée
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(accent, Colors.black, .55)!,
                    const Color(0xFF0B0810),
                    Colors.black,
                  ],
                ),
              ),
            ),
            if (hasCover)
              Opacity(
                opacity: .28,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Image.network(
                    t.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  // Barre du haut
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'EN LECTURE',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.55),
                                  fontSize: 11,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ctrl.queueLabel ?? 'Blowmusic',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.playlist_add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Ajouter à une playlist',
                          onPressed: () => bmAddToPlaylistSheet(context, t),
                        ),
                      ],
                    ),
                  ),
                  // Scène : disque + pochette dans le coin
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: w.width - 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _Pulse(
                              playing: playing,
                              size: disc,
                              accent: accent,
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              transitionBuilder: (c, a) => ScaleTransition(
                                scale: Tween(begin: .85, end: 1.0).animate(a),
                                child: FadeTransition(opacity: a, child: c),
                              ),
                              child: VinylDisc(
                                key: ValueKey('disc${t.id}'),
                                size: disc,
                                playing: playing && !loading,
                                accent: accent,
                                coverUrl: t.coverUrl,
                                // Activer pour avoir le logo de Blowmusic au centre du disque
                                // isCoverUrlAvailable: false,
                              ),
                            ),
                            if (hasCover)
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Transform.rotate(
                                  angle: -.09,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 450),
                                    child: Container(
                                      key: ValueKey('cov${t.id}'),
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(.85),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              .55,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                        image: DecorationImage(
                                          image: NetworkImage(t.coverUrl!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Positioned(
                            //   right: 0,
                            //   bottom: 0,
                            //   child: Transform.rotate(
                            //     angle: -.09,
                            //     child: AnimatedSwitcher(
                            //       duration: const Duration(milliseconds: 450),
                            //       child: Container(
                            //         key: ValueKey('cov${t.id}'),
                            //         width: 84,
                            //         height: 84,
                            //         decoration: BoxDecoration(
                            //           borderRadius: BorderRadius.circular(14),
                            //           border: Border.all(
                            //             color: Colors.white.withOpacity(.85),
                            //             width: 2,
                            //           ),
                            //           boxShadow: [
                            //             BoxShadow(
                            //               color: Colors.black.withOpacity(.55),
                            //               blurRadius: 16,
                            //               offset: const Offset(0, 8),
                            //             ),
                            //           ],
                            //           image: DecorationImage(
                            //             image: AssetImage(LOGO_BLOWMUSIC),
                            //             fit: BoxFit.cover,
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            if (loading)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Équaliseur
                  SizedBox(
                    height: 30,
                    child: AnimatedBuilder(
                      animation: _eq,
                      builder: (_, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 22; i++)
                            Container(
                              width: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: playing
                                  ? 5 +
                                        24 *
                                            (0.5 +
                                                    0.5 *
                                                        math.sin(
                                                          _eq.value *
                                                                  6.283 *
                                                                  2 +
                                                              i * .75,
                                                        ))
                                                .abs()
                                  : 4,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(.85),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Titre + favori
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (c, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(0, .25),
                                  end: Offset.zero,
                                ).animate(a),
                                child: c,
                              ),
                            ),
                            child: Column(
                              key: ValueKey('ti${t.id}'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.artistName ?? 'Artiste inconnu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.65),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Obx(() {
                          final fav = ctrl.favoriteIds.contains(t.id);
                          return IconButton(
                            onPressed: () => ctrl.toggleFavorite(t),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (c, a) =>
                                  ScaleTransition(scale: a, child: c),
                              child: Icon(
                                fav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(fav),
                                color: fav
                                    ? const Color(0xFFFB7185)
                                    : Colors.white70,
                                size: 30,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Barre de progression
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: accent,
                            inactiveTrackColor: Colors.white.withOpacity(.18),
                            thumbColor: Colors.white,
                          ),
                          child: Obx(() {
                            final dur = ctrl.duration.value.inMilliseconds
                                .toDouble();
                            final pos =
                                (_drag ??
                                        ctrl.position.value.inMilliseconds
                                            .toDouble())
                                    .clamp(0.0, dur > 0 ? dur : 1.0);
                            return Slider(
                              value: pos,
                              max: dur > 0 ? dur : 1.0,
                              onChanged: dur > 0
                                  ? (v) => setState(() => _drag = v)
                                  : null,
                              onChangeEnd: (v) {
                                ctrl.seekTo(Duration(milliseconds: v.toInt()));
                                setState(() => _drag = null);
                              },
                            );
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt(
                                  Duration(
                                    milliseconds:
                                        (_drag ??
                                                ctrl
                                                    .position
                                                    .value
                                                    .inMilliseconds
                                                    .toDouble())
                                            .toInt(),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _fmt(ctrl.duration.value),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Commandes
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(
                          () => _Tap(
                            onTap: ctrl.toggleShuffle,
                            child: Icon(
                              Icons.shuffle_rounded,
                              size: 28,
                              color: ctrl.shuffle.value
                                  ? accent
                                  : Colors.white54,
                            ),
                          ),
                        ),
                        _Tap(
                          onTap: ctrl.previous,
                          child: const Icon(
                            Icons.skip_previous_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                        _Tap(
                          onTap: ctrl.togglePlayPause,
                          scale: .9,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  accent,
                                  Color.lerp(
                                    accent,
                                    const Color(0xFF7C3AED),
                                    .6,
                                  )!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(.55),
                                  blurRadius: playing ? 28 : 12,
                                  spreadRadius: playing ? 3 : 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      transitionBuilder: (c, a) =>
                                          ScaleTransition(
                                            scale: a,
                                            child: RotationTransition(
                                              turns: Tween(
                                                begin: .85,
                                                end: 1.0,
                                              ).animate(a),
                                              child: c,
                                            ),
                                          ),
                                      child: Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        key: ValueKey(playing),
                                        size: 46,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        _Tap(
                          onTap: () => ctrl.next(),
                          child: const Icon(
                            Icons.skip_next_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                        Obx(() {
                          final m = ctrl.repeatMode.value;
                          return _Tap(
                            onTap: ctrl.cycleRepeat,
                            child: Icon(
                              m == 2
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              size: 28,
                              color: m == 0 ? Colors.white54 : accent,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Pied : file d'attente
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showQueue(context, accent),
                          icon: const Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white70,
                          ),
                          label: Obx(
                            () => Text(
                              'File d\'attente (${ctrl.queue.length})',
                              style: const TextStyle(color: Colors.white70),
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
        );
      }),
    );
  }

  void _showQueue(BuildContext context, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17121D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'File d\'attente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: ctrl.queue.length,
                    onReorder: ctrl.reorderQueue,
                    itemBuilder: (_, i) {
                      final q = ctrl.queue[i];
                      final cur = i == ctrl.queueIndex.value;
                      return ListTile(
                        key: ValueKey('q${q.id}_$i'),
                        leading: SizedBox(
                          width: 30,
                          child: Center(
                            child: cur
                                ? Icon(Icons.equalizer_rounded, color: accent)
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          q.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cur ? accent : Colors.white,
                            fontWeight: cur ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          q.artistName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!cur)
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () => ctrl.removeFromQueue(i),
                              ),
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => ctrl.playTrack(q),
                      );
                    },
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

/// Halo qui « respire » derrière le disque.
class _Pulse extends StatefulWidget {
  final bool playing;
  final double size;
  final Color accent;
  const _Pulse({
    required this.playing,
    required this.size,
    required this.accent,
  });

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Pulse o) {
    super.didUpdateWidget(o);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.playing && _c.isAnimating) {
      _c.animateTo(0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final s = widget.size * (1.06 + _c.value * .14);
        return Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.accent.withOpacity(.0),
                widget.accent.withOpacity(.12 + _c.value * .18),
              ],
              stops: const [.72, 1],
            ),
          ),
        );
      },
    );
  }
}

/// Bouton avec petit effet d'enfoncement (scale) au toucher.
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _Tap({required this.child, required this.onTap, this.scale = .82});

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
