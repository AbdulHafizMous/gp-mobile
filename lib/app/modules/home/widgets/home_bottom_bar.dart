// lib/app/modules/home/widgets/home_bottom_bar.dart
//
// Extrait de home_view.dart (fichier devenu trop lourd) — barre de
// navigation par sections (Social/Club/Media/Bizz) de Grandpublic.

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/components/module_bottom_bar.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class SectionsBottomBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const SectionsBottomBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Rendu délégué au composant partagé ModuleBottomBar (identique à
    // l'ancien rendu : la section « Club » (index 2) inverse les contrastes).
    return ModuleBottomBar(
      activeIndex: activeIndex,
      onTap: onTap,
      backgroundColor: GPTheme.colorForSection(activeIndex),
      accentColor: GPTheme.primaryColor,
      altIndex: 2,
      altColor: GPTheme.colorForSection(2),
      items: [
        for (final i in sections.asMap().keys)
          ModuleBottomBarItem(
            icon: sections[i].icon,
            label: sections[i].title,
            color: GPTheme.colorForSection(i),
            hidden: shouldSkipMedia && i == 0,
          ),
      ],
    );
  }
}
