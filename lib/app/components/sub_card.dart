// lib/app/components/sub_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/modules/social_premium/controllers/social_premium_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get subtleText => Theme.of(this).hintColor;
}

class SubCard extends StatelessWidget {
  const SubCard({
    super.key,
    required this.subscription,
    this.isActivePlan = false,
    this.hasActiveSubscription = false,
  });

  final Subscription subscription;

  /// Ce plan est-il le plan actif de l'utilisateur ?
  final bool isActivePlan;

  /// L'utilisateur a-t-il un abonnement actif (peu importe le plan) ?
  final bool hasActiveSubscription;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // Ancienne logique : price >= 10000  →  remplacée par : c'est le plan actif
    final Color accentColor = isActivePlan
        ? (isDark ? Colors.white : Colors.black)
        : GPTheme.primaryColor;

    return Card(
      color: context.theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      clipBehavior: Clip.hardEdge,
      elevation: 5,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: 280,
            height: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(LOGO_PIXEL, width: 70),
                const SizedBox(height: 8),
                Text(
                  subscription.duration,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${subscription.price.toStringAsFixed(0)} - XOF',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subscription.shortDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? context.subtleText : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Bouton : désactivé si c'est le plan actif ────────────
                isActivePlan
                    ? _ActivePlanButton(
                        accentColor: accentColor,
                        isDark: isDark,
                      )
                    : _SubscribeButton(
                        subscription: subscription,
                        accentColor: accentColor,
                        isDark: isDark,
                        hasActiveSubscription: hasActiveSubscription,
                      ),

                const SizedBox(height: 10),
                const _LegalLinksRow(),
              ],
            ),
          ),

          // ── Le petit carré incliné (design original intact) ────────────
          Positioned(
            top: -20,
            left: -10,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(15 / 360),
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Liens obligatoires (Guideline 3.1.2c) — CGU + Politique de confidentialité,
// visibles directement sur l'écran d'achat de l'abonnement.
class _LegalLinksRow extends StatelessWidget {
  const _LegalLinksRow();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11, color: context.subtleText);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _open('https://grandpublic.bj/cgu'),
          child: Text("Conditions d'utilisation", style: style.copyWith(decoration: TextDecoration.underline)),
        ),
        Text('  ·  ', style: style),
        GestureDetector(
          onTap: () => _open('https://grandpublic.bj/politique-de-confidentialite'),
          child: Text('Confidentialité', style: style.copyWith(decoration: TextDecoration.underline)),
        ),
      ],
    );
  }
}

// ── Bouton "Plan actuel" (plan déjà actif) ────────────────────────────────────
class _ActivePlanButton extends StatelessWidget {
  const _ActivePlanButton({required this.accentColor, required this.isDark});

  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: null, // désactivé
      icon: Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: isDark ? Colors.white54 : Colors.black38,
      ),
      label: Text(
        'Plan actuel',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white54 : Colors.black38,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── Bouton "S'abonner" / "Changer de plan" ────────────────────────────────────
class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.subscription,
    required this.accentColor,
    required this.isDark,
    required this.hasActiveSubscription,
  });

  final Subscription subscription;
  final Color accentColor;
  final bool isDark;
  final bool hasActiveSubscription;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<SocialPremiumController>()
        ? Get.find<SocialPremiumController>()
        : Get.put(SocialPremiumController());

    return Obx(
      () => ElevatedButton(
        onPressed: ctrl.isSubscribing.value
            ? null
            : () => ctrl.handleSubscribe(
                context: context,
                plan: subscription,
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            ctrl.isSubscribing.value &&
                ctrl.selectedPlan.value?.id == subscription.id
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                hasActiveSubscription ? 'Changer de plan' : 'S\'abonner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: (isActivePlan && isDark) ? Colors.black : Colors.white,
                ),
              ),
      ),
    );
  }

  // ignore: unused_element
  bool get isActivePlan => false; // non actif ici par définition
}