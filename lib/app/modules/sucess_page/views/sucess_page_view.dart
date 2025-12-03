import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/sucess_page_controller.dart';

class SucessPageView extends GetView<SucessPageController> {
  const SucessPageView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GPTheme.primaryColor,
      body: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Card(
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/success_logo.png",
                        width: 250,
                        height: 250,
                        cacheHeight: 250,
                        cacheWidth: 250,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Félicitations",
                        style: TextStyle(
                          color: GPTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Votre compte est prêt",
                        style: TextStyle(
                          color: Color.fromARGB(255, 122, 121, 121),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Image.asset(
                        "assets/images/checked.png",
                        width: 40,
                        height: 40,
                        cacheHeight: 40,
                        cacheWidth: 40,
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: "COMMENCEZ",
              callback: () {
                Get.offAllNamed('/interest');
              },
            ),
          ],
        ),
      ),
    );
  }
}
