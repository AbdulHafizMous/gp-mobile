import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

/// Pastille « centre d'intérêt ».
/// - fromProfile=false : posée sur fond primaire (blanc / contour blanc).
/// - fromProfile=true  : posée sur fond de page (clair/sombre). Sélectionné =
///   fond plein [accent] + texte lisible ; non sélectionné = contour [accent]
///   + texte lisible selon le thème (plus jamais « tout en primaire »).
/// La pastille prend sa largeur naturelle (pas de pleine largeur) pour que
/// plusieurs s'alignent par ligne dans un Wrap.
class InterestItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool fromProfile;
  final VoidCallback onTap;
  final Color? accent;

  const InterestItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.fromProfile = false,
    this.accent,
  });

  Color _accent(bool isDark) {
    if (accent != null) return accent!;
    try {
      return isDark ? SectionHelper.color : SectionHelper.colorAdjusted;
    } catch (_) {
      return GPTheme.primaryColor; // HomeController absent (hors Grandpublic)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = _accent(isDark);

    late Color bg, border, fg;
    if (!fromProfile) {
      bg = isSelected ? Colors.white : Colors.transparent;
      border = Colors.white;
      fg = isSelected ? GPTheme.primaryColor : Colors.white;
    } else if (isSelected) {
      bg = a;
      border = a;
      // Texte sur fond plein : noir si l'accent est clair (ex. jaune Club).
      fg = a.computeLuminance() > 0.6 ? Colors.black : Colors.white;
    } else {
      bg = Colors.transparent;
      border = isDark ? Colors.white30 : Colors.black26;
      fg = isDark ? Colors.white70 : Colors.black87;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 15),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(width: 1, color: border),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isSelected && fromProfile) ...[
              Icon(Icons.check_rounded, size: 15, color: fg),
              const SizedBox(width: 5),
            ],
            Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13.5)),
          ]),
        ),
      ),
    );
  }
}
