import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/components/primary_loading_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/reset_password_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: context.isDark ? null : GPTheme.primaryColor,
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
              //     Icons.lock_outline_rounded,
              //     color: Colors.white,
              //     size: 36,
              //   ),
              // ),
              // const SizedBox(height: 24),

              // ── Titre ──────────────────────────────────────────────────
              const Text(
                'Nouveau mot de passe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choisissez un nouveau mot de passe\npour sécuriser votre compte.',
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
                    // ── Nouveau mot de passe ─────────────────────────────
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        obscureText: controller.isObscureNew.value,
                         style: TextStyle(
                              color: context.isDark ? Colors.black : null,
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir un nouveau mot de passe';
                          }
                          if (value.length < 8) {
                            return 'Minimum 8 caractères';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Nouveau mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => controller.isObscureNew.value =
                                !controller.isObscureNew.value,
                            icon: Icon(
                              controller.isObscureNew.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Confirmation mot de passe ────────────────────────
                    Obx(
                      () => TextFormField(
                        controller: controller.confirmController,
                        obscureText: controller.isObscureConfirm.value,
                         style: TextStyle(
                              color: context.isDark ? Colors.black : null,
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer votre mot de passe';
                          }
                          if (value != controller.passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Confirmer le mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => controller.isObscureConfirm.value =
                                !controller.isObscureConfirm.value,
                            icon: Icon(
                              controller.isObscureConfirm.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Indicateur force du mot de passe ─────────────────────────────
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.passwordController,
                      builder: (_, value, _) {
                        final pass = value.text;
                        if (pass.isEmpty) return const SizedBox.shrink();
                        final strength = _passwordStrength(pass);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: strength.value,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  strength.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strength.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    // ── Bouton ───────────────────────────────────────────
                    Obx(
                      () => controller.isLoading.value
                          ? const PrimaryLoadingButton()
                          : PrimaryButton(
                              text: 'RÉINITIALISER',
                              callback: controller.resetPassword,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Indicateur de force du mot de passe ──────────────────────────────────
  _PasswordStrength _passwordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) {
      return _PasswordStrength(0.2, Colors.red.shade400, 'Très faible');
    } else if (score == 2) {
      return _PasswordStrength(0.4, Colors.orange.shade400, 'Faible');
    } else if (score == 3) {
      return _PasswordStrength(0.6, Colors.yellow.shade700, 'Moyen');
    } else if (score == 4) {
      return _PasswordStrength(0.8, Colors.lightGreen, 'Fort');
    } else {
      return _PasswordStrength(1.0, Colors.green, 'Très fort');
    }
  }
}

class _PasswordStrength {
  final double value;
  final Color color;
  final String label;
  const _PasswordStrength(this.value, this.color, this.label);
}
