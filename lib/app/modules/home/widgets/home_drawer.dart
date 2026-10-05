// lib/app/modules/home/widgets/home_drawer.dart
//
// Extrait de home_view.dart (fichier devenu trop lourd) — drawer dynamique
// de Grand Public : profil, menus de la section active, menus fixes
// (Premium/Liens/À propos/Blow Music/GameZ), déconnexion.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/drawer_btn.dart';
import 'package:grand_public_v2/app/components/drawer_parts.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get subtleText => Theme.of(this).hintColor;
  // Color get dividerColor => Theme.of(this).dividerColor;
}

class HomeDrawer extends StatelessWidget {
  final int activeSectionIndex;

  const HomeDrawer({super.key, required this.activeSectionIndex});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final isDark = context.isDark;
    final userRole = activeUser.value.role;
    final section = sections[activeSectionIndex];

    final dynamicItems = section.drawerItems.where((item) {
      if (item.requiredRoles.isEmpty) return true;
      return item.requiredRoles.contains(userRole);
    }).toList();

    final sectionColor = GPTheme.colorForSection(activeSectionIndex);
    final linkColor = GPTheme.contentColorForSection(activeSectionIndex);

    return DrawerShell(
      color: sectionColor,
      children: [
          DrawerProfileHeader(onTap: () => ctrl.navigateTo('/profile'), accentColor: linkColor),
          const SizedBox(height: 20),
          DrawerSectionLabel(
            icon: section.icon,
            title: section.title,
            lightColor: SectionHelper.index == 2 ? Colors.black : null,
          ),
          const SizedBox(height: 10),
          if (dynamicItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Aucun menu disponible',
                style: TextStyle(color: isDark ? context.subtleText : Colors.white.withAlpha(130), fontSize: 13),
              ),
            )
          else
            ...dynamicItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DrawerBtn(
                  title: item.title,
                  icon: _dynamicIcon(item),
                  flutterIcon: item.icon,
                  callback: () => ctrl.navigateTo(item.route ?? ''),
                  accentColor: linkColor,
                ),
              ),
            ),
          const DrawerSep(),
          ...fixedDrawerItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DrawerBtn(
                title: item.title,
                icon: _fixedIcon(item.route),
                keepIconColors: item.route == '/blowmusic/home' || item.route == '/gamez/home',
                callback: () => ctrl.navigateTo(item.route ?? ''),
                accentColor: linkColor,
              ),
            ),
          ),
          const DrawerSep(),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DrawerBtn(
              title: 'Déconnexion',
              flutterIcon: Icons.logout_rounded,
              callback: () => Get.find<HomeController>().logout(),
              accentColor: linkColor,
            ),
          ),
          const SizedBox(height: 20),
          DrawerLogo(
            asset: GPTheme.logoForSection(activeSectionIndex),
            onTap: () => ctrl.goToSection(0, showToast: false),
          ),
          const SizedBox(height: 20),
      ],
    );
  }

  String _dynamicIcon(DrawerItem item) => 'assets/icons/portrait.png';

  String _fixedIcon(String? route) {
    switch (route) {
      case '/social-premium':
        return 'assets/icons/premium.png';
      case '/social-link':
        return 'assets/icons/link.png';
      case '/social-about':
        return 'assets/icons/info.png';
      case '/blowmusic/home':
        return LOGO_BLOWMUSIC_NAV;
      case '/gamez/home':
        return LOGO_GAMEZ_NAV;
      default:
        return 'assets/icons/portrait.png';
    }
  }
}
