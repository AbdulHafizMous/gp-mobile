// lib/app/modules/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/drawer_btn.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/modules/notifs/controllers/notifs_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/constants/index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOME VIEW — layout shell
// ─────────────────────────────────────────────────────────────────────────────
class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final notifsController = Get.put(NotifsPageController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canPop = controller.canPop;
      final sectionIdx = controller.activeSectionIndex;

      return Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: context.isDark
            ? const Color(0xFF0A0A0A)
            : GPTheme.colorForSection(sectionIdx),
        appBar: _HomeAppBar(
          ctrl: controller,
          canPop: canPop,
          currentRoute: controller.currentRoute,
          sectionIndex: sectionIdx,
        ),
        drawer: _DynamicDrawer(activeSectionIndex: sectionIdx),
        body: _AnimatedBody(
          routeKey: controller.currentRoute,
          child: controller.currentPage,
        ),
        bottomNavigationBar: _SectionsBottomBar(
          activeIndex: sectionIdx,
          notificationCount: notifsController.unreadCount.value,
          onTap: (i) => controller.goToSection(i),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Couleurs dynamiques basées sur le thème
  Color get subtleText => Theme.of(this).hintColor;
  Color get dividerColor => Theme.of(this).dividerColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED BODY  — slide + fade entre destinations
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedBody extends StatelessWidget {
  final String routeKey;
  final Widget child;

  const _AnimatedBody({required this.routeKey, required this.child});

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

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController ctrl;
  final bool canPop;
  final String currentRoute;
  final int sectionIndex;

  const _HomeAppBar({
    required this.ctrl,
    required this.canPop,
    required this.currentRoute,
    required this.sectionIndex,
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
      // Si sous-page → bouton retour ; sinon → bouton hamburger
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
              onPressed: ctrl.popPage,
            )
          : IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () => ctrl.scaffoldKey.currentState?.openDrawer(),
            ),
      title: InkWell(
        onTap: () {
          if (canPop) {
            // Retour à la racine de la section
            ctrl.goToSection(ctrl.activeSectionIndex, showToast: false);
          } else {
            ctrl.goToSection(0, showToast: false);
          }
        },
        child: Image.asset(
          GPTheme.logoForSection(sectionIndex),
          height: 44,
          width: 44,
          filterQuality: FilterQuality.high,
        ),
        // Container(
        //   height: 44,
        //   width: 44,
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     image: DecorationImage(
        //       image: AssetImage(LOGO_PIXEL),
        //       fit: BoxFit.contain,
        //     ),
        //     borderRadius: BorderRadius.circular(60),
        //     border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        //   ),
        //   // child: Image.asset(
        //   //   LOGO_PIXEL,
        //   //   height: 44,
        //   //   width: 44,
        //   //   cacheHeight: 44,
        //   //   cacheWidth: 44,
        //   // ),
        // ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => ctrl.navigateTo('/notifs'),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          onPressed: () => ctrl.navigateTo('/profile'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SectionsBottomBar extends StatelessWidget {
  final int activeIndex;
  final int notificationCount;
  final ValueChanged<int> onTap;

  const _SectionsBottomBar({
    required this.activeIndex,
    required this.notificationCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF0A0A0A)
            : GPTheme.colorForSection(activeIndex),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final i in sections.asMap().keys)
            if (!(skipMediaOnIos && i == 0)) _buildItem(context, i),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int i) {
          final isSelected = activeIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      sections[i].icon,
                      size: 24,
                      color: isSelected
                          ? GPTheme.colorForSection(i)
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                  child: Text(
                    sections[i].title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DYNAMIC DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class _DynamicDrawer extends StatelessWidget {
  final int activeSectionIndex;

  const _DynamicDrawer({required this.activeSectionIndex});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final isDark = context.isDark;
    final userRole = activeUser
        .value
        .role; // GetStorage().read<String>('userRole') ?? 'user';
    final section = sections[activeSectionIndex];

    final dynamicItems = section.drawerItems.where((item) {
      if (item.requiredRoles.isEmpty) return true;
      return item.requiredRoles.contains(userRole);
    }).toList();

    final sectionColor = GPTheme.colorForSection(activeSectionIndex);
    // Couleur lisible sur la pill blanche des liens (voir DrawerBtn) —
    // différente de sectionColor pour Club (jaune trop clair pour du texte).
    final linkColor = GPTheme.contentColorForSection(activeSectionIndex);

    return Drawer(
      // En Light: couleur de la section active / En Dark: Noir profond
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : sectionColor,
      width: MediaQuery.of(context).size.width * 0.72,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Profile header ─────────────────────────────────────────────
          _DrawerProfileHeader(
            onTap: () => ctrl.navigateTo('/profile'),
            accentColor: sectionColor,
          ),

          const SizedBox(height: 20),

          // ── Section label ──────────────────────────────────────────────
          _DrawerSectionLabel(section: section),

          const SizedBox(height: 10),

          // ── Dynamic items ──────────────────────────────────────────────
          if (dynamicItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Aucun menu disponible',
                style: TextStyle(
                  // Adapté selon le fond (blanc cassé sur rouge / gris sur noir)
                  color: isDark
                      ? context.subtleText
                      : Colors.white.withAlpha(130),
                  fontSize: 13,
                ),
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

          // ── Divider ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(
              color: isDark
                  ? context.dividerColor
                  : Colors.white.withAlpha(130),
            ),
          ),

          // ── Fixed items ────────────────────────────────────────────────
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
            child: Divider(
              color: isDark
                  ? context.dividerColor
                  : Colors.white.withAlpha(130),
            ),
          ),

          // ── Logout ─────────────────────────────────────────────────────
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
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    GPTheme.logoForSection(activeSectionIndex),
                  ),
                ),
              ),
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
      default:
        return 'assets/icons/portrait.png';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER PROFILE HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerProfileHeader extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const _DrawerProfileHeader({required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final username = activeUser.value.name;
    // GetStorage().read<String>('username') ?? 'Utilisateur';
    final email =
        activeUser.value.email; // GetStorage().read<String>('email') ?? '';
    final avatarUrl =
        activeUser.value.avatarUrl ??
        ''; // GetStorage().read<String>('avatarUrl') ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Fond blanc en light, gris très sombre en dark pour garder le contraste
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        padding: const EdgeInsets.only(top: 30, left: 6, right: 6),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
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
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation(
                                  accentColor,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/profile.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/profile.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Text(
              username,
              style: TextStyle(
                fontSize: 18,
                fontFamily: "gotham_book",
                fontWeight: FontWeight.bold,
                // Couleur de section en light, Blanc en dark pour lisibilité sur fond sombre
                color: isDark ? Colors.white : accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? context.subtleText : accentColor.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerSectionLabel extends StatelessWidget {
  final SectionModel section;
  const _DrawerSectionLabel({required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // En mode light (fond rouge), on reste sur du blanc pur.
    // En mode dark (fond noir), on utilise le rouge primary pour faire ressortir la section.
    final Color contentColor = isDark
        ? Colors
              .white // GPTheme.primaryColor
        : Colors.white.withValues(alpha: 0.95);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Icon(section.icon, size: 14, color: contentColor),
          const SizedBox(width: 6),
          Text(
            section.title.toUpperCase(),
            style: TextStyle(
              color: contentColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}