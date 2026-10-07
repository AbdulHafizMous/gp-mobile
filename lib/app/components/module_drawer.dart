// lib/app/components/module_drawer.dart
//
// Drawer partagé par BlowMusic et GameZ — même architecture/principe que
// le drawer Grandpublic (home_drawer.dart) : en-tête profil (avatar +
// nom + email), section "menu variable" (les onglets du module), section
// "menu fixe" (changer de module, déconnexion), logo du module en bas.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/components/drawer_btn.dart';
import 'package:grand_public_v2/app/components/drawer_parts.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';

/// Ouvre l'écran Notifications directement sur la catégorie du module
/// (« blowmusic » ou « gamez »).
void openModuleNotifications(String categoryId) {
  final ctrl = Get.isRegistered<NotifsPageController>()
      ? Get.find<NotifsPageController>()
      : Get.put(NotifsPageController());
  ctrl.selectedCategory.value = categoryId;
  ctrl.fetchNotifications(refresh: true);
  Get.toNamed('/notifs');
}

class ModuleDrawerNavItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const ModuleDrawerNavItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
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

  /// Un bouton identique à ceux du drawer Grandpublic (DrawerBtn).
  Widget _btn({
    String title = '',
    IconData? icon,
    String? asset,
    bool keepColors = false,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DrawerBtn(
      title: title,
      flutterIcon: icon,
      icon: asset ?? 'assets/images/profile.png',
      keepIconColors: keepColors,
      accentColor: accentColor,
      callback: () {
        Get.back();
        onTap();
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DrawerShell(
      color: accentColor,
      children: [
        // ── En-tête profil : STRICTEMENT celui de Grandpublic ─────────
        DrawerProfileHeader(
          onTap: () => Get.toNamed('/profile'),
          accentColor: accentColor,
        ),
        const SizedBox(height: 20),

        // ── Menu variable (onglets du module) ──────────────────────────
        DrawerSectionLabel(title: moduleName),
        const SizedBox(height: 10),
        if (variableItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Aucun menu disponible',
              style: TextStyle(
                color: isDark
                    ? Theme.of(context).hintColor
                    : Colors.white.withAlpha(130),
                fontSize: 13,
              ),
            ),
          )
        else
          ...variableItems.map(
            (item) =>
                _btn(title: item.title, icon: item.icon, onTap: item.onTap),
          ),
        const DrawerSep(),

        // ── Menu fixe (comme Premium/Liens/À propos de Grandpublic) ───
        _btn(
          title: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: () => openModuleNotifications(
            moduleName == 'Blowmusic'
                ? 'blowmusic'
                : moduleName == 'GameZ'
                ? 'gamez'
                : 'all',
          ),
        ),
        if (moduleName != 'Grandpublic')
          _btn(
            title: 'Grandpublic',
            asset: LOGO_PIXEL,
            keepColors: true,
            onTap: () => _switchTo(AppMode.grandPublic, '/home'),
          ),
        if (isBlowMusicActivated && moduleName != 'Blowmusic')
          _btn(
            title: 'Blowmusic',
            asset: LOGO_BLOWMUSIC,
            keepColors: true,
            onTap: () => _switchTo(AppMode.blowMusic, '/blowmusic/home'),
          ),
        if (isGameZActivated && moduleName != 'GameZ')
          _btn(
            title: 'GameZ',
            asset: LOGO_GAMEZ,
            keepColors: true,
            onTap: () => _switchTo(AppMode.gameZ, '/gamez/home'),
          ),
        const DrawerSep(),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DrawerBtn(
            title: 'Déconnexion',
            flutterIcon: Icons.logout_rounded,
            accentColor: accentColor,
            callback: () {
              activeUser.value = User.empty();
              GetStorage().erase();
              Get.offAllNamed('/login');
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Logo du module en bas (même conteneur que Grandpublic) ────
        DrawerLogo(asset: moduleLogo),
        const SizedBox(height: 20),
      ],
    );
  }
}
