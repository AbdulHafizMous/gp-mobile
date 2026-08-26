// lib/app/components/drawer_btn.dart
// Mise à jour : accepte un IconData (flutterIcon) en plus du asset PNG (icon)

import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class DrawerBtn extends StatelessWidget {
  const DrawerBtn({
    super.key,
    this.title = "",
    this.icon = 'assets/images/profile.png',
    this.flutterIcon,
    this.callback,
    this.accentColor,
  });

  final String title;

  /// Chemin vers un asset PNG (utilisé si [flutterIcon] est null)
  final String icon;

  /// IconData Material (prioritaire sur [icon] si fourni)
  final IconData? flutterIcon;

  final dynamic callback;

  /// Couleur du texte/icône en light mode (pill blanche). Doit rester
  /// lisible sur fond blanc — pour Club, passer GPTheme.clubOnColor (pas
  /// clubColor, trop clair). Défaut : rouge "main" (Espaces / items fixes).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final lightColor = accentColor ?? GPTheme.primaryColor;

    return InkWell(
      onTap: () => callback != null ? callback() : Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(30),
          color: isDark ? Colors.transparent : Colors.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            // ── Icône (Flutter icon prioritaire, sinon asset PNG) ────────
            SizedBox(
              width: 24,
              height: 24,
              child: flutterIcon != null
                  ? Icon(
                      flutterIcon,
                      color: !isDark ? lightColor : Colors.white,
                      size: 20,
                    )
                  : Image.asset(
                      icon,
                      width: 20,
                      height: 20,
                      color: !isDark ? lightColor : Colors.white,
                    ),
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: !isDark ? lightColor : Colors.white,
              ),
            ),

            const Spacer(),

            Icon(
              Icons.arrow_forward_ios,
              color: !isDark ? lightColor : Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
