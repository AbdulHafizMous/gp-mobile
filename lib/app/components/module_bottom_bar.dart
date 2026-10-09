// lib/app/components/module_bottom_bar.dart
//
// Barre de navigation basse partagée par Grandpublic (SectionsBottomBar),
// Blowmusic et Youwiiin : mêmes dimensions, mêmes animations (pastille
// ronde + icône qui grossit + libellé qui passe en gras). Seuls les items
// et les couleurs changent d'un module à l'autre.

import 'package:flutter/material.dart';

/// Un onglet de la barre. [color] = couleur de l'icône quand l'onglet est
/// sélectionné (par défaut : [ModuleBottomBar.accentColor]).
class ModuleBottomBarItem {
  final IconData icon;
  final String label;
  final Color? color;

  /// Masque l'onglet sans décaler les index renvoyés à [onTap]
  /// (ex. section « Espaces » masquée dans Grandpublic).
  final bool hidden;

  const ModuleBottomBarItem({
    required this.icon,
    required this.label,
    this.color,
    this.hidden = false,
  });
}

class ModuleBottomBar extends StatelessWidget {
  final List<ModuleBottomBarItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  /// Fond en thème clair (souvent la couleur du module).
  final Color backgroundColor;

  /// Fond en thème sombre.
  final Color darkBackgroundColor;

  /// Couleur d'accent des icônes sélectionnées quand l'item n'a pas de couleur.
  final Color accentColor;

  /// Index d'un onglet « clair sur fond clair » (ex. Club, jaune) qui
  /// inverse les contrastes quand il est actif. Null = pas de cas particulier.
  final int? altIndex;

  /// Couleur utilisée pour [altIndex] en thème sombre.
  final Color? altColor;

  const ModuleBottomBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
    required this.backgroundColor,
    required this.accentColor,
    this.darkBackgroundColor = const Color(0xFF0A0A0A),
    this.altIndex,
    this.altColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: isDark ? darkBackgroundColor : backgroundColor,
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
          for (var i = 0; i < items.length; i++)
            if (!items[i].hidden) _buildItem(context, i, isDark),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int i, bool isDark) {
    final item = items[i];
    final isSelected = activeIndex == i;
    // Cas particulier : onglet actif = altIndex (contrastes inversés).
    final alt = altIndex != null && activeIndex == altIndex;
    final altCol = altColor ?? accentColor;
    final itemColor = item.color ?? accentColor;

    final Color iconColor;
    if (alt && isDark && i != altIndex) {
      iconColor = altCol;
    } else if (alt && isDark && i == altIndex) {
      iconColor = Colors.black;
    } else if (alt && !isDark && i != altIndex) {
      iconColor = Colors.black;
    } else if (isSelected) {
      iconColor = itemColor;
    } else {
      iconColor = Colors.white.withValues(alpha: 0.4);
    }

    final Color labelColor;
    if (alt && isDark) {
      labelColor = altCol;
    } else if (alt && !isDark) {
      labelColor = Colors.black;
    } else if (isSelected) {
      labelColor = Colors.white;
    } else {
      labelColor = Colors.white38;
    }

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
              color: isSelected
                  ? (alt ? (isDark ? altCol : Colors.black) : Colors.white)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(item.icon, size: 24, color: iconColor),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: labelColor,
            ),
            child: Text(item.label, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
