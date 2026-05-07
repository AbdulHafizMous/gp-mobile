import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/social_about/controllers/social_about_controller.dart';

class AboutPage extends GetView<SocialAboutController> {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: On s'assure que le controller est bien là 
    // Si tu as peur qu'il manque, on peut faire un Get.put() ici, 
    // mais le Binding est préférable.
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/wall_start.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Utilisation de Expanded pour éviter les overflows
            child: ListView(
              controller: controller.scrollController, // Renommé pour plus de clarté
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: const [
                SizedBox(height: 400),
                _AboutText(
                  text: "Bienvenue sur Grand Public,",
                  fontSize: 20,
                  isTitle: true,
                ),
                _AboutText(text: "Votre plateforme dédiée aux contenus vidéo exclusifs. Découvrez et partagez,"),
                _AboutText(text: "Portrait : Rencontrez des personnes fascinantes et découvrez leurs parcours inspirants."),
                _AboutText(text: "Opinion : Partagez des idées et des réflexions sur les grandes questions d'actualité."),
                _AboutText(text: "Expérience : Vivez des moments extraordinaires à travers les témoignages de ceux qui osent l'inédit."),
                _AboutText(text: "PARTAGEONS LES GRANDS MOMENTS."),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                Text(
                  "www.grandpublic.online",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tel: +229 63 63 44 44",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Petit widget interne pour éviter la répétition des styles
class _AboutText extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isTitle;

  const _AboutText({required this.text, this.fontSize = 15, this.isTitle = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white, 
          fontSize: fontSize,
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}