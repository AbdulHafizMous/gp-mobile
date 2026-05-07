import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/about.dart';
import '../controllers/social_about_controller.dart';

class SocialAboutView extends GetView<SocialAboutController> {
  const SocialAboutView({super.key});

  @override
  Widget build(BuildContext context) {
    // Si tu reçois l'erreur "not found", force l'injection ici :
    if (!Get.isRegistered<SocialAboutController>()) {
       Get.put(SocialAboutController());
    }

    return const Scaffold(
      body: AboutPage(),
    );
  }
}