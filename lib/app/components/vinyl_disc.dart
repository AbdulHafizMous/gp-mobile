// lib/app/components/vinyl_disc.dart
//
// Disque vinyle qui tourne EN CONTINU (rotation complète, sans à-coup) tant
// que `playing` est vrai ; à l'arrêt il garde son angle. Pochette optionnelle
// au centre (étiquette du disque).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/constants/index.dart';

class VinylDisc extends StatefulWidget {
  final double size;
  final bool playing;
  final Color accent;
  final String? coverUrl;
  final bool isCoverUrlAvailable;
  final IconData fallbackIcon;
  final Duration period;

  VinylDisc({
    super.key,
    required this.size,
    required this.playing,
    required this.accent,
    this.coverUrl,
    this.isCoverUrlAvailable = true,
    this.fallbackIcon = Icons.music_note_rounded,
    this.period = const Duration(seconds: 7),
  });

  @override
  State<VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<VinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(VinylDisc old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat(); // reprend depuis l'angle courant, sans saut
    } else if (!widget.playing && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final label = s * .36;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.rotate(angle: _c.value * 2 * math.pi, child: child),
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B0B0F),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withOpacity(.45),
                      blurRadius: s * .14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: Size(s, s),
                painter: _GroovePainter(widget.accent),
              ),
              Container(
                alignment: Alignment.center,
                width: label,
                height: label,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accent,
                      const Color(0xFF7C3AED),
                      const Color(0xFFE11D48),
                    ],
                  ),
                  border: Border.all(color: Colors.black, width: s * .012),
                ),
                child: !widget.isCoverUrlAvailable
                    ? ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            LOGO_BLOWMUSIC,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              widget.fallbackIcon,
                              color: Colors.white,
                              size: label * .5,
                            ),
                          ),
                        ),
                      )
                    : ClipOval(
                        child:
                            (widget.coverUrl != null &&
                                widget.coverUrl!.isNotEmpty)
                            ? Image.network(
                                widget.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.fallbackIcon,
                                  color: Colors.white,
                                  size: label * .5,
                                ),
                              )
                            : Icon(
                                widget.fallbackIcon,
                                color: Colors.white,
                                size: label * .5,
                              ),
                      ),
              ),
              Container(
                width: s * .035,
                height: s * .035,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0B0B0F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroovePainter extends CustomPainter {
  final Color accent;
  _GroovePainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 14; i++) {
      final rr = r * (.42 + i * .04);
      p.color = Colors.white.withOpacity(i.isEven ? .07 : .035);
      canvas.drawCircle(c, rr, p);
    }
    // reflets : deux secteurs lumineux opposés (font « vivre » la rotation)
    final shine = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(.14),
          Colors.transparent,
          Colors.transparent,
          Colors.white.withOpacity(.14),
          Colors.transparent,
        ],
        stops: const [0, .08, .16, .5, .58, .66],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r * .97, shine);
    canvas.drawCircle(
      c,
      r - .5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withOpacity(.5),
    );
  }

  @override
  bool shouldRepaint(covariant _GroovePainter old) => old.accent != accent;
}
