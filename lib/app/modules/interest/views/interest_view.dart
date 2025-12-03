import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/interest_item.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/interest_controller.dart';

class InterestView extends GetView<InterestController> {
  const InterestView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GPTheme.primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset(
              "assets/images/logo_pixel.png",
              width: 150,
              height: 150,
              cacheHeight: 150,
              cacheWidth: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ce que vous aimez',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 2),
              child: Divider(height: 2, color: Colors.white),
            ),
            const SizedBox(height: 20),
            GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              padding: const EdgeInsets.all(10),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                InterestItem(title: "Sport"),
                InterestItem(title: "Mode"),
                InterestItem(title: "Dance"),
                InterestItem(title: "Lecture"),
                InterestItem(title: "Sorties"),
                InterestItem(title: "Voyage"),
                InterestItem(title: "Shopping"),
                InterestItem(title: "Dessin"),
                InterestItem(title: "Cuisine"),
                InterestItem(title: "Réseaux sociaux"),
                InterestItem(title: "Music"),
                InterestItem(title: "Cinéma"),
              ],
            ),
            const SizedBox(height: 50),
            PrimaryButton(
              text: "C'EST TOUT",
              callback: () => controller.goHome(),
            ),
          ],
        ),
      ),
    );
  }
}
