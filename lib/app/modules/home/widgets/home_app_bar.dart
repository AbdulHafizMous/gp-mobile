// lib/app/modules/home/widgets/home_app_bar.dart
//
// Extrait de home_view.dart (fichier devenu trop lourd) — AppBar de la
// coquille Grandpublic (logo, notifications, profil).

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController ctrl;
  final bool canPop;
  final String currentRoute;
  final int sectionIndex;
  final int notificationCount;

  const HomeAppBar({
    super.key,
    required this.ctrl,
    required this.canPop,
    required this.currentRoute,
    required this.sectionIndex,
    required this.notificationCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.isDark
          ? const Color(0xFF0A0A0A)
          : GPTheme.colorForSection(sectionIndex),
      elevation: 0,
      centerTitle: true,
      leading: canPop
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: (SectionHelper.index == 2 && !context.isDark)
                    ? Colors.black
                    : Colors.white,
                size: 24,
              ),
              onPressed: ctrl.popPage,
            )
          : IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: (SectionHelper.index == 2 && !context.isDark)
                    ? Colors.black
                    : Colors.white,
                size: 26,
              ),
              onPressed: () => ctrl.scaffoldKey.currentState?.openDrawer(),
            ),
      title: SizedBox(
        height: 25,
        child: InkWell(
          onTap: () {
            if (canPop) {
              ctrl.goToSection(ctrl.activeSectionIndex, showToast: false);
            } else {
              ctrl.goToSection(0, showToast: false);
            }
          },
          child: Image.asset(
            ctrl.activeSectionIndex == 2 && !context.isDark
                ? LOGO_NAV_Dark_Club
                : LOGO_NAV,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: (SectionHelper.index == 2 && !context.isDark)
                    ? Colors.black
                    : Colors.white,
              ),
              onPressed: () => ctrl.navigateTo('/notifs'),
            ),
            if (notificationCount > 0)
              Positioned(
                right: 4,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (SectionHelper.index == 2 && !context.isDark)
                          ? Colors.black
                          : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    notificationCount > 99
                        ? '99+'
                        : notificationCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.person_outline_rounded,
            color: (SectionHelper.index == 2 && !context.isDark)
                ? Colors.black
                : Colors.white,
          ),
          onPressed: () => ctrl.navigateTo('/profile'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
