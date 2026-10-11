// lib/app/modules/youwiiin/widgets/youwiiin_style.dart
//
// Jetons de design Youwiiin : alignés sur le thème de l'app (GPTheme.primaryColor,
// fond noir / blanc des écrans Grandpublic, cartes #1A1A1A en sombre), rayons et
// espacements partagés par tous les écrans du module.

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class YwStyle {
  final bool dark;
  const YwStyle._(this.dark);

  factory YwStyle.of(BuildContext context) => YwStyle._(Theme.of(context).brightness == Brightness.dark);

  Color get bg => dark ? Colors.black : Colors.white;
  Color get card => dark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
  Color get sheet => dark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get fg => dark ? Colors.white : Colors.black87;
  Color get sub => fg.withValues(alpha: .6);
  Color get faint => fg.withValues(alpha: .08);
  Color get accent => GPTheme.primaryColor;

  /// Texte / icône posés sur la couleur primaire.
  static const Color onAccent = Colors.white;
  static const Color ok = Color(0xFF16A34A);
  static const Color warn = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  static const double rCard = 18;
  static const double rBtn = 16;
  static const double rSheet = 26;
  static const double minTap = 44;

  static const RoundedRectangleBorder sheetShape = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet)));
}

/// Pastille de compte (badge) : blanche sur fond primaire, primaire sinon.
class YwCountBadge extends StatelessWidget {
  final int count;
  final bool onAccent;
  const YwCountBadge({super.key, required this.count, this.onAccent = false});

  @override
  Widget build(BuildContext context) {
    final accent = GPTheme.primaryColor;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: onAccent ? Colors.white : accent, borderRadius: BorderRadius.circular(20)),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(color: onAccent ? accent : Colors.white, fontSize: 11, fontWeight: FontWeight.w900, height: 1.1),
      ),
    );
  }
}

/// Puce de choix (≥ 44 de haut) : primaire plein si sélectionnée, texte lisible dessus.
class YwChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const YwChoiceChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? .4 : 1,
      child: Material(
        color: selected ? st.accent : st.faint,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: YwStyle.minTap, minWidth: YwStyle.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(label, style: TextStyle(color: selected ? YwStyle.onAccent : st.fg, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton principal plein (primaire, texte blanc) ou contour, hauteur 50, rayon partagé.
class YwButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;
  final bool busy;
  final Color? color;
  const YwButton({super.key, required this.label, required this.icon, required this.onTap, this.outlined = false, this.busy = false, this.color});

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(YwStyle.rBtn));
    final text = Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15));
    final lead = busy
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: outlined ? (color ?? st.fg) : YwStyle.onAccent))
        : Icon(icon, size: 20);
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: busy ? null : onTap,
              style: OutlinedButton.styleFrom(foregroundColor: color ?? st.fg, side: BorderSide(color: (color ?? st.fg).withValues(alpha: .35)), shape: shape),
              icon: lead,
              label: text,
            )
          : ElevatedButton.icon(
              onPressed: busy ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? st.accent,
                foregroundColor: YwStyle.onAccent,
                disabledBackgroundColor: st.faint,
                elevation: 0,
                shape: shape,
              ),
              icon: lead,
              label: text,
            ),
    );
  }
}
