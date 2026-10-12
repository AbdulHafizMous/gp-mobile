// lib/app/modules/youwiiin/widgets/youwiiin_confirm_dialog.dart
//
// Dialogue de confirmation Youwiiin (quitter / annuler / abandonner).
// Carte arrondie aux couleurs du thème, pastille d'icône, encart de conséquence,
// deux boutons pleine largeur empilés : le choix SÛR est le bouton principal.
// Renvoie true si l'utilisateur confirme l'action destructive, false sinon.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'youwiiin_style.dart';

Future<bool> showYouwiiinConfirm(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool danger = true,
  String? consequence,
  bool barrierDismissible = false,
}) async {
  HapticFeedback.mediumImpact();
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: cancelLabel,
    barrierColor: Colors.black.withValues(alpha: .6),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, __) => _ConfirmCard(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      consequence: consequence,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween<double>(begin: .92, end: 1).animate(curved), child: child),
      );
    },
  );
  return r ?? false;
}

class _ConfirmCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final String? consequence;
  const _ConfirmCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
    required this.consequence,
  });

  @override
  Widget build(BuildContext context) {
    final st = YwStyle.of(context);
    final tone = danger ? YwStyle.danger : st.accent;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(YwStyle.rBtn));
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: st.sheet,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [st.accent.withValues(alpha: st.dark ? .14 : .08), st.sheet],
                  ),
                  border: Border.all(color: st.accent.withValues(alpha: .28), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: st.dark ? .5 : .18), blurRadius: 40, offset: const Offset(0, 16))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: tone.withValues(alpha: .14)),
                      child: Icon(icon, size: 30, color: tone),
                    ),
                    const SizedBox(height: 16),
                    Text(title, textAlign: TextAlign.center, style: TextStyle(color: st.fg, fontSize: 21, fontWeight: FontWeight.w900, height: 1.2)),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center, style: TextStyle(color: st.sub, fontSize: 14.5, height: 1.45)),
                    if (consequence != null && consequence!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: (danger ? YwStyle.danger : st.accent).withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (danger ? YwStyle.danger : st.accent).withValues(alpha: .25)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: tone),
                          const SizedBox(width: 10),
                          Expanded(child: Text(consequence!, style: TextStyle(color: st.fg, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.4))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 22),
                    // Choix sûr : bouton principal (primaire).
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        autofocus: true,
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(backgroundColor: st.accent, foregroundColor: YwStyle.onAccent, elevation: 0, shape: shape),
                        child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(true);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: danger ? YwStyle.danger : st.fg,
                          side: BorderSide(color: (danger ? YwStyle.danger : st.fg).withValues(alpha: .6), width: 1.4),
                          shape: shape,
                        ),
                        child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
