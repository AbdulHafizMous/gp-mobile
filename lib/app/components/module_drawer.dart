// lib/app/components/module_drawer.dart
//
// Drawer partagé par BlowMusic et GameZ : même architecture que le drawer
// Grand Public (en-tête profil, liens, déconnexion) mais avec la couleur
// d'accent du module. Permet aussi de basculer vers les autres modules.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

class ModuleDrawer extends StatelessWidget {
  final Color accentColor;
  final String moduleName;
  const ModuleDrawer({super.key, required this.accentColor, required this.moduleName});

  void _switchTo(AppMode mode, String route) {
    AppModeService.setMode(mode);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final username = GetStorage().read<String>('username') ?? 'Utilisateur';
    return Drawer(
      backgroundColor: const Color(0xFF111116),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(radius: 26, backgroundColor: accentColor, child: const Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(moduleName, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            _tile(context, Icons.home_rounded, 'Accueil $moduleName', () => Get.back()),
            _tile(context, Icons.person_outline_rounded, 'Mon profil', () => Get.toNamed('/profile')),
            _tile(context, Icons.notifications_none_rounded, 'Notifications', () => Get.toNamed('/notifs')),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text('CHANGER DE MODULE', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            if (moduleName != 'Grand Public')
              _tile(context, Icons.public_rounded, 'Grand Public', () => _switchTo(AppMode.grandPublic, '/home')),
            if (isBlowMusicActivated && moduleName != 'Blow Music')
              _tile(context, Icons.graphic_eq_rounded, 'Blow Music', () => _switchTo(AppMode.blowMusic, '/blowmusic/home')),
            if (isGameZActivated && moduleName != 'GameZ')
              _tile(context, Icons.sports_esports_rounded, 'GameZ', () => _switchTo(AppMode.gameZ, '/gamez/home')),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Divider(color: Colors.white12)),
            _tile(context, Icons.logout_rounded, 'Déconnexion', () {
              GetStorage().remove('token');
              GetStorage().write('isLogged', false);
              Get.offAllNamed('/login');
            }),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: accentColor),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: onTap,
    );
  }
}
