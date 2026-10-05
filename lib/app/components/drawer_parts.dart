// lib/app/components/drawer_parts.dart
//
// Éléments de drawer PARTAGÉS par Grand Public (home_drawer.dart) et les
// modules Blow Music / GameZ (module_drawer.dart) : mêmes en-tête profil,
// libellé de section, séparateur, coque (fond + largeur) et logo du bas.
// Toute modification visuelle se fait ici et s'applique aux trois drawers.

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/globals/index.dart';

class DrawerStyle {
  DrawerStyle._();
  static const double widthFactor = 0.72;
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkHeaderBg = Color(0xFF2C2C2C);
  static const double logoHeight = 100;
}

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Coque du drawer : fond (couleur de section en clair, noir en sombre) + largeur.
class DrawerShell extends StatelessWidget {
  final Color color;
  final List<Widget> children;
  const DrawerShell({super.key, required this.color, required this.children});

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: _dark(context) ? DrawerStyle.darkBg : color,
        width: MediaQuery.of(context).size.width * DrawerStyle.widthFactor,
        child: ListView(padding: EdgeInsets.zero, children: children),
      );
}

class DrawerSep extends StatelessWidget {
  const DrawerSep({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Divider(color: _dark(context) ? Theme.of(context).dividerColor : Colors.white.withAlpha(130)),
      );
}

class DrawerSectionLabel extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Color? lightColor; // couleur du libellé en mode clair
  const DrawerSectionLabel({super.key, this.icon, required this.title, this.lightColor});

  @override
  Widget build(BuildContext context) {
    final c = _dark(context) ? Colors.white : (lightColor ?? Colors.white.withValues(alpha: 0.95));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: c), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerLogo extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  const DrawerLogo({super.key, required this.asset, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: DrawerStyle.logoHeight,
          decoration: BoxDecoration(image: DecorationImage(image: AssetImage(asset))),
        ),
      );
}

class DrawerProfileHeader extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const DrawerProfileHeader({super.key, required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = (Theme.of(context).brightness == Brightness.dark);
    final username = activeUser.value.name;
    final email = activeUser.value.email;
    final avatarUrl = activeUser.value.avatarUrl ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isDark ?  DrawerStyle.darkHeaderBg : Colors.white,
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
              style: TextStyle(fontSize: 13, color: isDark ? Theme.of(context).hintColor : accentColor.withOpacity(0.7)),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
