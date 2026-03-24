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

            const SizedBox(height: 30),

            /// LISTE DYNAMIQUE
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: GPTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 15,
                    runSpacing: 15,
                    children: controller.interests.map((interest) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InterestItem(
                            title: interest.name,
                            isSelected: interest.isSelected,
                            onTap: () => controller.toggleInterest(interest),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

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
