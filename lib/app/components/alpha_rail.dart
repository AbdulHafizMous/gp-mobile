// lib/app/components/alpha_rail.dart
//
// Index alphabétique vertical réutilisable (même principe que Youwiiin) :
//  - tap ou glisser, effet « vague » autour du doigt, retour haptique
//  - lettre active mise en avant, lettres sans entrée grisées
//  - AlphaRailHost gère l'apparition (uniquement quand la liste A-Z est
//    visible à l'écran) : glissement + fondu, et la bulle centrale.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlphaRailController {
  final active = ValueNotifier<String>('');
  final show = ValueNotifier<bool>(false);
  final bubble = ValueNotifier<String?>(null);
  bool busy = false;
  String? _lastTarget;

  void dispose() {
    active.dispose();
    show.dispose();
    bubble.dispose();
  }
}

/// Superpose le rail (côté droit) et la bulle de lettre à [child].
class AlphaRailHost extends StatefulWidget {
  final Widget child;
  final AlphaRailController ctrl;
  final List<String> letters; // toutes les lettres affichées dans le rail
  final Set<String> enabled; // lettres ayant au moins une entrée
  final ValueChanged<String> onJump; // fait défiler jusqu'à la lettre
  final Color accent, fg;
  final bool isDark;
  final bool enabledRail; // false : rail jamais affiché (ex. recherche active)
  final double top, bottom;

  const AlphaRailHost({
    super.key,
    required this.child,
    required this.ctrl,
    required this.letters,
    required this.enabled,
    required this.onJump,
    required this.accent,
    required this.fg,
    required this.isDark,
    this.enabledRail = true,
    this.top = 8,
    this.bottom = 8,
  });

  @override
  State<AlphaRailHost> createState() => _AlphaRailHostState();
}

class _AlphaRailHostState extends State<AlphaRailHost> {
  String _lastBubble = '';

  String? _resolve(String letter) {
    if (widget.enabled.isEmpty) return null;
    if (widget.enabled.contains(letter)) return letter;
    final i = widget.letters.indexOf(letter);
    for (var k = i < 0 ? 0 : i; k < widget.letters.length; k++) {
      if (widget.enabled.contains(widget.letters[k])) return widget.letters[k];
    }
    return widget.enabled.last;
  }

  void _pick(String letter) {
    final c = widget.ctrl;
    final target = _resolve(letter);
    if (target == null) return;
    c.busy = true;
    if (target == c._lastTarget) return;
    c._lastTarget = target;
    c.bubble.value = target;
    c.active.value = target;
    HapticFeedback.selectionClick();
    widget.onJump(target);
  }

  void _release() {
    final c = widget.ctrl;
    c.busy = false;
    c._lastTarget = null;
    c.bubble.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.ctrl;
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (widget.enabledRail && widget.enabled.isNotEmpty)
          Positioned(
            right: 2,
            top: widget.top,
            bottom: widget.bottom,
            child: ValueListenableBuilder<bool>(
              valueListenable: c.show,
              builder: (_, show, child) => IgnorePointer(
                ignoring: !show,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  offset: show ? Offset.zero : const Offset(1.4, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: show ? 1 : 0,
                    child: child,
                  ),
                ),
              ),
              child: SizedBox(
                width: 30,
                child: _Rail(
                  letters: widget.letters,
                  enabled: widget.enabled,
                  active: c.active,
                  onPick: _pick,
                  onRelease: _release,
                  accent: widget.accent,
                  fg: widget.fg,
                  isDark: widget.isDark,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: ValueListenableBuilder<String?>(
                valueListenable: c.bubble,
                builder: (_, v, __) {
                  if (v != null) _lastBubble = v;
                  return AnimatedScale(
                    scale: v != null ? 1 : .5,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: v != null ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accent,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: .45),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          _lastBubble,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Rail extends StatefulWidget {
  final List<String> letters;
  final Set<String> enabled;
  final ValueListenable<String> active;
  final ValueChanged<String> onPick;
  final VoidCallback onRelease;
  final Color accent, fg;
  final bool isDark;
  const _Rail({
    required this.letters,
    required this.enabled,
    required this.active,
    required this.onPick,
    required this.onRelease,
    required this.accent,
    required this.fg,
    required this.isDark,
  });

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> {
  double? _finger;
  int _lastIdx = -1;

  void _touch(double dy, double itemH) {
    final n = widget.letters.length;
    final idx = (dy / itemH).floor().clamp(0, n - 1);
    setState(() => _finger = dy / itemH - .5);
    if (idx != _lastIdx) {
      _lastIdx = idx;
      widget.onPick(widget.letters[idx]);
    }
  }

  void _release() {
    _lastIdx = -1;
    if (mounted) setState(() => _finger = null);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.letters;
    final n = letters.length;
    return LayoutBuilder(
      builder: (_, cons) {
        final itemH = math.min(22.0, cons.maxHeight / n);
        final h = itemH * n;
        final pressed = _finger != null;
        final fontSize = itemH >= 17 ? 11.5 : 9.5;
        return Align(
          alignment: Alignment.center,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _touch(e.localPosition.dy, itemH),
            onPointerMove: (e) => _touch(e.localPosition.dy, itemH),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: ValueListenableBuilder<String>(
              valueListenable: widget.active,
              builder: (_, act, __) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: h,
                decoration: BoxDecoration(
                  color: pressed
                      ? (widget.isDark
                            ? Colors.white.withValues(alpha: .12)
                            : Colors.black.withValues(alpha: .08))
                      : (widget.isDark
                            ? Colors.black.withValues(alpha: .35)
                            : Colors.white.withValues(alpha: .75)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < n; i++)
                      SizedBox(
                        height: itemH,
                        child: Builder(builder: (_) {
                          final l = letters[i];
                          final isAct = l == act;
                          final on = widget.enabled.contains(l);
                          final f = pressed
                              ? (1 - (i - _finger!).abs() / 3).clamp(0.0, 1.0)
                              : 0.0;
                          return AnimatedSlide(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            offset: Offset(-.7 * f, 0),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              scale: 1 + .9 * f + (isAct && !pressed ? .25 : 0),
                              child: Center(
                                child: Text(
                                  l,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: isAct || f > .5
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: isAct
                                        ? widget.accent
                                        : on
                                        ? widget.fg.withValues(alpha: .7)
                                        : widget.fg.withValues(alpha: .2),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
