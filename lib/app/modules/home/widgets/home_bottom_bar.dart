// lib/app/modules/home/widgets/home_bottom_bar.dart
//
// Extrait de home_view.dart (fichier devenu trop lourd) — barre de
// navigation par sections (Social/Club/Media/Bizz) de Grand Public.

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class SectionsBottomBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const SectionsBottomBar({super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF0A0A0A) : GPTheme.colorForSection(activeIndex),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final i in sections.asMap().keys)
            if (!(shouldSkipMedia && i == 0)) _buildItem(context, i),
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
              color: isSelected
                  ? (activeIndex == 2 ? (context.isDark ? GPTheme.colorForSection(2) : Colors.black) : Colors.white)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                sections[i].icon,
                size: 24,
                color: (i != 2 && context.isDark && activeIndex == 2)
                    ? GPTheme.colorForSection(2)
                    : (i == 2 && context.isDark && activeIndex == 2)
                    ? Colors.black
                    : (activeIndex == 2 && i != 2 && !context.isDark)
                    ? Colors.black
                    : isSelected
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: (activeIndex == 2 && context.isDark)
                  ? GPTheme.colorForSection(2)
                  : (activeIndex == 2 && !context.isDark)
                  ? Colors.black
                  : isSelected
                  ? Colors.white
                  : Colors.white38,
            ),
            child: Text(sections[i].title, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
