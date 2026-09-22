import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/services/app_mode_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/onboarding_controller.dart';

/// Écran d'accueil (fond "wall_start").
///
/// - `isBlowMusicActivated == false` (par défaut) : comportement STRICTEMENT
///   inchangé, un seul bouton "Démarrer" qui va au login Grand Public.
/// - `isBlowMusicActivated == true` : le même écran propose en plus un
///   second bouton pour entrer dans Blow Music, qui a ensuite son propre
///   logo/thème/menus (voir lib/app/modules/blowmusic/).
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  void _enterGrandPublic() {
    AppModeService.setMode(AppMode.grandPublic);
    Get.offNamed("/login");
  }

  void _enterBlowMusic() {
    AppModeService.setMode(AppMode.blowMusic);
    Get.offNamed("/login");
  }

  Future<void> _openCgu() async {
    final uri = Uri.parse('$WEBSITE_URL/cgu');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCguNotice() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          children: [
            const TextSpan(text: 'En continuant, vous acceptez nos '),
            TextSpan(
              text: 'Conditions Générales d\'Utilisation',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = _openCgu,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/wall_start.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isBlowMusicActivated)
              // ── Comportement actuel, inchangé ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: PrimaryButton(
                      text: "Démarrer",
                      callback: () => _enterGrandPublic(),
                    ),
                  ),
                ],
              )
            else
              // ── Choix entre les deux applications ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Choisissez votre expérience",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: "Grand Public",
                        callback: () => _enterGrandPublic(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _enterBlowMusic(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          side: const BorderSide(color: Colors.white, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Blow Music",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildCguNotice(),
            const SizedBox(height: 65),
          ],
        ),
      ),
    );
  }
}
