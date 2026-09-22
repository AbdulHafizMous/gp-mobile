// lib/app/modules/blowmusic/views/blowmusic_home_view.dart
//
// Coquille visuelle de Blow Music : logo dédié, thème dédié, bottom nav
// dédiée — se comporte comme une application à part alors qu'elle vit dans
// le même projet Flutter et partage la même session/API que Grand Public.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:grand_public_v2/app/constants/index.dart';

import '../controllers/blowmusic_controller.dart';

// Identité visuelle propre à Blow Music (indépendante de GPTheme).
class _BlowMusicTheme {
  static const Color primary = Color(0xFF7B2FF7); // violet distinct de GP
  static const Color background = Color(0xFF0E0B16);
}

class BlowMusicHomeView extends GetView<BlowMusicController> {
  const BlowMusicHomeView({super.key});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'home':
        return Icons.home_rounded;
      case 'explore':
        return Icons.explore_rounded;
      case 'library':
        return Icons.library_music_rounded;
      case 'profile':
        return Icons.person_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BlowMusicTheme.background,
      appBar: AppBar(
        backgroundColor: _BlowMusicTheme.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            // Remplacer par Image.asset(LOGO_BLOWMUSIC) une fois l'asset livré.
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _BlowMusicTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Blow Music',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Changer d\'application',
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white70),
            onPressed: controller.switchToGrandPublic,
          ),
        ],
      ),
      body: Obx(
        () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(kBlowMusicTabs[controller.currentTab.value].icon),
                color: Colors.white24,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                '${kBlowMusicTabs[controller.currentTab.value].label} — Bientôt disponible',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          backgroundColor: _BlowMusicTheme.background,
          selectedItemColor: _BlowMusicTheme.primary,
          unselectedItemColor: Colors.white38,
          currentIndex: controller.currentTab.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          items: kBlowMusicTabs
              .map(
                (t) => BottomNavigationBarItem(
                  icon: Icon(_iconFor(t.icon)),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
