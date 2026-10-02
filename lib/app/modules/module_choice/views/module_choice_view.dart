// lib/app/modules/module_choice/views/module_choice_view.dart
//
// Écran de choix de module, affiché UNE FOIS juste après la
// connexion/inscription (voir AppModeService.postAuthRoute). Ensuite,
// le changement de module se fait depuis le menu (drawer) de chaque
// module — voir _ModuleSwitchTile dans home_view.dart.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/module_choice_controller.dart';

class ModuleChoiceView extends GetView<ModuleChoiceController> {
  const ModuleChoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = <_ModuleCardData>[
      _ModuleCardData(
        mode: AppMode.grandPublic,
        title: 'Grand Public',
        subtitle: 'Social, Club, Media & Bizz',
        color: const Color(0xFF23232E),
        icon: Icons.public_rounded,
        logo: LOGO_NAV,
      ),
      if (isBlowMusicActivated)
        _ModuleCardData(
          mode: AppMode.blowMusic,
          title: 'Blow Music',
          subtitle: 'Radio live, playlists & musique',
          color: GPTheme.primaryColor,
          icon: Icons.graphic_eq_rounded,
          logo: LOGO_BLOWMUSIC,
        ),
      if (isGameZActivated)
        _ModuleCardData(
          mode: AppMode.gameZ,
          title: 'GameZ',
          subtitle: 'Jeux, classements & récompenses',
          color: GPTheme.clubColor,
          icon: Icons.sports_esports_rounded,
          logo: LOGO_GAMEZ,
        ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/wall_start.png'), fit: BoxFit.cover),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.55), // lisibilité du texte sur la photo
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Bienvenue 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Que voulez-vous ouvrir ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 32),
                  ...modules.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _ModuleCard(data: m, onTap: () => controller.choose(m.mode)),
                      )),
                  const SizedBox(height: 10),
                  Text(
                    'Vous pourrez changer de module à tout moment depuis le menu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCardData {
  final AppMode mode;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String? logo;
  _ModuleCardData({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.logo,
  });
}

class _ModuleCard extends StatelessWidget {
  final _ModuleCardData data;
  final VoidCallback onTap;
  const _ModuleCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [data.color, data.color.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: data.color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: data.logo != null
                  ? Image.asset(
                      data.logo!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(data.icon, color: Colors.white, size: 30),
                    )
                  : Icon(data.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
