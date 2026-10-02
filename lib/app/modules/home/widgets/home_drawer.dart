// lib/app/modules/home/widgets/home_drawer.dart
//
// Extrait de home_view.dart (fichier devenu trop lourd) — drawer dynamique
// de Grand Public : profil, menus de la section active, menus fixes
// (Premium/Liens/À propos/Blow Music/GameZ), déconnexion.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/drawer_btn.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get subtleText => Theme.of(this).hintColor;
  Color get dividerColor => Theme.of(this).dividerColor;
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

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : sectionColor,
      width: MediaQuery.of(context).size.width * 0.72,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DrawerProfileHeader(onTap: () => ctrl.navigateTo('/profile'), accentColor: linkColor),
          const SizedBox(height: 20),
          _DrawerSectionLabel(section: section),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(color: isDark ? context.dividerColor : Colors.white.withAlpha(130)),
          ),
          ...fixedDrawerItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DrawerBtn(
                title: item.title,
                icon: _fixedIcon(item.route),
                callback: () => ctrl.navigateTo(item.route ?? ''),
                accentColor: linkColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(color: isDark ? context.dividerColor : Colors.white.withAlpha(130)),
          ),
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
          InkWell(
            onTap: () => ctrl.goToSection(0, showToast: false),
            child: Container(
              height: 100,
              decoration: BoxDecoration(image: DecorationImage(image: AssetImage(GPTheme.logoForSection(activeSectionIndex)))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
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

class _DrawerProfileHeader extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const _DrawerProfileHeader({required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final username = activeUser.value.name;
    final email = activeUser.value.email;
    final avatarUrl = activeUser.value.avatarUrl ?? '';

    return GestureDetector(
      onTap: onTap,
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
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation(accentColor),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => ColorFiltered(
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
              username,
              style: TextStyle(
                fontSize: 18,
                fontFamily: "gotham_book",
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              email,
              style: TextStyle(fontSize: 13, color: isDark ? context.subtleText : accentColor.withOpacity(0.7)),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final SectionModel section;
  const _DrawerSectionLabel({required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final Color contentColor = isDark
        ? Colors.white
        : SectionHelper.index == 2
        ? Colors.black
        : Colors.white.withValues(alpha: 0.95);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Icon(section.icon, size: 14, color: contentColor),
          const SizedBox(width: 6),
          Text(
            section.title.toUpperCase(),
            style: TextStyle(color: contentColor, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}
