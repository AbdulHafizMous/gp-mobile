import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/components/primary_loading_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GPTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                LOGO_PIXEL,
                height: 110,
                width: 110,
                cacheHeight: 110,
                cacheWidth: 110,
              ),
              const SizedBox(height: 32),

              // ── Icône ──────────────────────────────────────────────────
              // Container(
              //   width: 72,
              //   height: 72,
              //   decoration: BoxDecoration(
              //     color: Colors.white.withValues(alpha: 0.12),
              //     shape: BoxShape.circle,
              //     border: Border.all(
              //       color: Colors.white.withValues(alpha: 0.25),
              //     ),
              //   ),
              //   child: const Icon(
              //     Icons.lock_reset_rounded,
              //     color: Colors.white,
              //     size: 36,
              //   ),
              // ),
              // const SizedBox(height: 24),

              // ── Titre ──────────────────────────────────────────────────
              const Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Saisissez votre email et nous vous enverrons\nun code pour réinitialiser votre mot de passe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // ── Form ───────────────────────────────────────────────────
              Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre email';
                        }
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(value.trim())) {
                          return 'Veuillez saisir un email valide';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Adresse email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Bouton ───────────────────────────────────────────
                    Obx(
                      () => controller.isLoading.value
                          ? const PrimaryLoadingButton()
                          : PrimaryButton(
                              text: 'ENVOYER LE CODE',
                              callback: controller.sendResetCode,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Retour login ───────────────────────────────────────────
              TextButton.icon(
                onPressed: () => Get.offNamed('/login'),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                label: const Text(
                  'Retour à la connexion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}