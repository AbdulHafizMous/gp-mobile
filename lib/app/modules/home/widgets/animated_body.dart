// lib/app/modules/home/widgets/animated_body.dart
//
// Extrait de home_view.dart (fichier devenu trop lourd) — transition
// slide + fade entre destinations de la coquille Grandpublic.

import 'package:flutter/material.dart';

class AnimatedBody extends StatelessWidget {
  final String routeKey;
  final Widget child;

  const AnimatedBody({super.key, required this.routeKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: CurvedAnimation(
          parent: anim,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0.01),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(routeKey), child: child),
    );
  }
}
