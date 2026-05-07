import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/sucess_page_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class SucessPageView extends GetView<SucessPageController> {
  const SucessPageView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? null : GPTheme.primaryColor,
      body: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withAlpha(30)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Image.asset(
                        "assets/images/success_logo.png",
                        width: 190,
                        height: 180,
                        cacheHeight: 180,
                        cacheWidth: 190,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Félicitations",
                        style: TextStyle(
                          color: GPTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Votre compte est prêt",
                        style: TextStyle(
                          color: Color.fromARGB(255, 122, 121, 121),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Image.asset(
                        "assets/images/checked.png",
                        width: 40,
                        height: 40,
                        cacheHeight: 40,
                        cacheWidth: 40,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              PrimaryButton(
                text: "COMMENCEZ",
                callback: () {
                  // If we should remove Interest Step Here - Just send to /main-page
                  Get.offAllNamed('/interest');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
