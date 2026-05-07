import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/components/primary_loading_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/confirm_controller.dart';


// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class ConfirmView extends GetView<ConfirmController> {
  const ConfirmView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: context.isDark ? null : GPTheme.primaryColor,
      body: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset(
                LOGO_PIXEL,
                height: 150,
                width: 150,
                cacheHeight: 150,
                cacheWidth: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                "Veuillez saisir votre code de confirmation",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OtpTextField(
                numberOfFields: 4,
                fillColor: Colors.white,
                filled: true,
                borderColor: Colors.black,
                autoFocus: true,
                cursorColor: Colors.black,
                focusedBorderColor: Colors.black,
                showFieldAsBox: true,
                onCodeChanged: (String code) {
                  controller.otpCode.value = code;
                },
                fieldWidth: 64,
                onSubmit: (String verificationCode) {
                  controller.verifyOtp(verificationCode);
                },
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  "Consultez votre mail et saisissez le code de confirmation reçu.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Obx(
                () => !controller.canResend.value
                    ? Text(
                        controller.timerLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : controller.isResendLoading.value
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: controller.regenerateOtp,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => controller.isLoading.value
                    ? const PrimaryLoadingButton()
                    : PrimaryButton(
                        text: "CONFIRMER",
                        callback: () =>
                            controller.verifyOtp(controller.otpCode.value),
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
