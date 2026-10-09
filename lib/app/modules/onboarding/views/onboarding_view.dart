import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/onboarding_controller.dart';

/// Écran d'accueil (fond "wall_start"). Le choix du module (Grandpublic /
/// Blowmusic / Youwiiin) se fait maintenant APRÈS la connexion — voir
/// lib/app/modules/module_choice/. Cet écran ne fait donc plus que mener
/// au login, quel que soit le nombre de modules actifs.
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  Future<void> _openCgu() async {
    final uri = Uri.parse('$WEBSITE_URL/cgu');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCguNotice() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'En continuant, vous acceptez nos',
            style: TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          InkWell(
            onTap: _openCgu,
            child: Text(
              'Conditions Générales d\'Utilisation',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: 10.5,
              ),
            ),
          ),
          Text('.', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: PrimaryButton(
                    text: "Démarrer",
                    callback: () => Get.offNamed("/login"),
                  ),
                ),
              ],
            ),
            _buildCguNotice(),
            const SizedBox(height: 65),
          ],
        ),
      ),
    );
  }
}
