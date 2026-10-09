// lib/app/modules/youwiiin/widgets/youwiiin_confetti.dart
//
// Confettis maison (CustomPainter, aucune dépendance) + écran de fin de
// partie multijoueur animé (victoire / défaite / égalité).

import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Piece {
  final double x, vx, vy, size, rot, vr, delay;
  final Color color;
  final bool circle;
  _Piece(math.Random r, List<Color> palette)
    : x = r.nextDouble(),
      vx = (r.nextDouble() - .5) * .35,
      vy = .55 + r.nextDouble() * .7,
      size = 6 + r.nextDouble() * 8,
      rot = r.nextDouble() * math.pi * 2,
      vr = (r.nextDouble() - .5) * 12,
      delay = r.nextDouble() * .35,
      color = palette[r.nextInt(palette.length)],
      circle = r.nextBool();
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t; // 0..1
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final c in pieces) {
      final lt = ((t - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final x = (c.x + c.vx * lt) * size.width;
      // Chute avec légère gravité.
      final y = -20 + (c.vy * lt + .5 * lt * lt) * size.height * 1.1;
      p.color = c.color.withValues(alpha: (1 - lt * lt).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rot + c.vr * lt);
      if (c.circle) {
        canvas.drawCircle(Offset.zero, c.size / 2, p);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * .6), p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Pluie de confettis jouée une fois.
class YouwiiinConfetti extends StatefulWidget {
  final List<Color> colors;
  final int count;
  const YouwiiinConfetti({
    super.key,
    this.count = 90,
    this.colors = const [Color(0xFFEB2040), Color(0xFFFFC600), Color(0xFF0086C9), Color(0xFF22C55E), Colors.white],
  });

  @override
  State<YouwiiinConfetti> createState() => _YouwiiinConfettiState();
}

class _YouwiiinConfettiState extends State<YouwiiinConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
  late final List<_Piece> _pieces = () {
    final r = math.Random();
    return List.generate(widget.count, (_) => _Piece(r, widget.colors));
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_pieces, _c.value), size: Size.infinite),
    ),
  );
}

/// Écran de fin natif : [outcome] = win | lose | draw.
class YouwiiinEndOverlay extends StatelessWidget {
  final String outcome;
  final int gained;
  final String gameName;
  final bool cancelled;
  final List<({String name, int? score, bool winner})> ranking;
  final VoidCallback onClose;
  const YouwiiinEndOverlay({
    super.key,
    required this.outcome,
    required this.gained,
    required this.gameName,
    required this.ranking,
    required this.onClose,
    this.cancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final win = outcome == 'win';
    final draw = outcome == 'draw';
    final color = win ? const Color(0xFFFFC600) : (draw ? const Color(0xFF0086C9) : const Color(0xFF9CA3AF));
    final title = cancelled ? 'Partie annulée' : (win ? 'Victoire !' : (draw ? 'Égalité' : 'Défaite'));
    final subtitle = cancelled
        ? 'Les mises ont été remboursées.'
        : win
        ? 'Bravo, vous remportez la partie de $gameName.'
        : draw
        ? 'Les mises sont remboursées.'
        : 'Ce sera pour la prochaine fois.';
    final icon = win ? Icons.emoji_events_rounded : (draw ? Icons.handshake_rounded : Icons.sentiment_dissatisfied_rounded);

    return Material(
      color: Colors.black.withValues(alpha: .86),
      child: Stack(
        children: [
          if (win) const Positioned.fill(child: YouwiiinConfetti()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v.clamp(0.0, 1.2), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: .18),
                          border: Border.all(color: color, width: 3),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: .45), blurRadius: 36)],
                        ),
                        child: Icon(icon, color: color, size: 58),
                      ),
                      const SizedBox(height: 20),
                      Text(title, style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      if (gained > 0) ...[
                        const SizedBox(height: 18),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: gained),
                          duration: const Duration(milliseconds: 1100),
                          builder: (_, v, __) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFFFC600).withValues(alpha: .16), borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.toll_rounded, color: Color(0xFFFFC600)),
                                const SizedBox(width: 8),
                                Text('+$v GCoin', style: const TextStyle(color: Color(0xFFFFC600), fontWeight: FontWeight.w900, fontSize: 20)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (ranking.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        for (final r in ranking)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(r.winner ? Icons.emoji_events_rounded : Icons.person_rounded, size: 16, color: r.winner ? const Color(0xFFFFC600) : Colors.white38),
                                const SizedBox(width: 6),
                                Text(
                                  '${r.name}${r.score != null ? '  ·  ${r.score} pts' : ''}',
                                  style: TextStyle(color: r.winner ? Colors.white : Colors.white60, fontWeight: r.winner ? FontWeight.w800 : FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
