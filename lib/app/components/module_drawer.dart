// lib/app/components/module_drawer.dart
//
// Drawer partagé par BlowMusic et GameZ — même architecture/principe que
// le drawer Grand Public (home_drawer.dart) : en-tête profil (avatar +
// nom + email), section "menu variable" (les onglets du module), section
// "menu fixe" (changer de module, déconnexion), logo du module en bas.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

/// Ouvre l'écran Notifications directement sur la catégorie du module
/// (« blowmusic » ou « gamez »).
void openModuleNotifications(String categoryId) {
  final ctrl = Get.isRegistered<NotifsPageController>() ? Get.find<NotifsPageController>() : Get.put(NotifsPageController());
  ctrl.selectedCategory.value = categoryId;
  ctrl.fetchNotifications(refresh: true);
  Get.toNamed('/notifs');
}

class ModuleDrawerNavItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const ModuleDrawerNavItem({required this.title, required this.icon, required this.onTap});
}

class ModuleDrawer extends StatelessWidget {
  final Color accentColor;
  final String moduleName;
  final String moduleLogo;
  final List<ModuleDrawerNavItem> variableItems;

  const ModuleDrawer({
    super.key,
    required this.accentColor,
    required this.moduleName,
    required this.moduleLogo,
    this.variableItems = const [],
  });

  void _switchTo(AppMode mode, String route) {
    AppModeService.setMode(mode);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : accentColor,
      width: MediaQuery.of(context).size.width * 0.72,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── En-tête profil (même principe que Grand Public) ────────────
          GestureDetector(
            onTap: () => Get.toNamed('/profile'),
            child: Container(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              padding: const EdgeInsets.only(top: 30, left: 6, right: 6),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white12 : Colors.black12),
                    child: ClipOval(
                      child: (activeUser.value.hasAvatar)
                          ? Image.network(
                              activeUser.value.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => ColorFiltered(
                                colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                                child: Image.asset('assets/images/profile.png', fit: BoxFit.cover),
                              ),
                            )
                          : ColorFiltered(
                              colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                              child: Image.asset('assets/images/profile.png', fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  Text(
                    activeUser.value.name,
                    style: TextStyle(fontSize: 18, fontFamily: 'gotham_book', fontWeight: FontWeight.bold, color: isDark ? Colors.white : accentColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    activeUser.value.email,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : accentColor.withOpacity(0.7)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Menu variable (les onglets du module) ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              moduleName.toUpperCase(),
              style: TextStyle(color: isDark ? Colors.white : Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4),
            ),
          ),
          const SizedBox(height: 6),
          ...variableItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Icon(item.icon, color: isDark ? accentColor : Colors.white),
                  title: Text(item.title, style: TextStyle(color: isDark ? Colors.white : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Get.back();
                    item.onTap();
                  },
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(color: isDark ? Colors.white12 : Colors.white38),
          ),

          // ── Menu fixe (comme Premium/Liens/À propos de Grand Public) ───
          ListTile(
            leading: Icon(Icons.notifications_none_rounded, color: isDark ? accentColor : Colors.white),
            title: Text('Notifications', style: TextStyle(color: isDark ? Colors.white : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () {
              Get.back();
              openModuleNotifications(moduleName == 'Blow Music' ? 'blowmusic' : moduleName == 'GameZ' ? 'gamez' : 'all');
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text('CHANGER DE MODULE', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ),
          if (moduleName != 'Grand Public')
            _fixedItem(context, 'assets/images/icon.png', 'Grand Public', () => _switchTo(AppMode.grandPublic, '/home'), isDark),
          if (isBlowMusicActivated && moduleName != 'Blow Music')
            _fixedItem(context, LOGO_BLOWMUSIC_NAV, 'Blow Music', () => _switchTo(AppMode.blowMusic, '/blowmusic/home'), isDark),
          if (isGameZActivated && moduleName != 'GameZ')
            _fixedItem(context, LOGO_GAMEZ_NAV, 'GameZ', () => _switchTo(AppMode.gameZ, '/gamez/home'), isDark),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(color: isDark ? Colors.white12 : Colors.white38),
          ),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: isDark ? accentColor : Colors.white),
            title: Text('Déconnexion', style: TextStyle(color: isDark ? Colors.white : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () {
              GetStorage().remove('token');
              GetStorage().write('isLogged', false);
              Get.offAllNamed('/login');
            },
          ),
          const SizedBox(height: 20),

          // ── Logo du module en bas (comme Grand Public) ─────────────────
          Center(
            child: Image.asset(
              moduleLogo,
              height: 60,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _fixedItem(BuildContext context, String logo, String title, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.apps_rounded, color: isDark ? accentColor : Colors.white)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }
}
