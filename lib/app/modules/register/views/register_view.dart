import 'dart:io' show Platform;

import 'package:country_pickers/country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_field.dart';
import 'package:grand_public_v2/app/components/audience_fields.dart';
import 'package:grand_public_v2/app/components/country_picker.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/components/primary_loading_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/shared/widgets/social_buttons.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
// import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../controllers/register_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSocial = controller.isSocialCompletion;

      return Scaffold(
        backgroundColor: context.isDark ? null : GPTheme.primaryColor,
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  LOGO_PIXEL,
                  height: 120,
                  width: 120,
                  cacheHeight: 120,
                  cacheWidth: 120,
                ),
                // Container(
                //   padding: const EdgeInsets.all(2),
                //   width: 120,
                //   height: 120,
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     image: DecorationImage(
                //       image: AssetImage(LOGO_PIXEL),
                //       fit: BoxFit.contain,
                //       scale: 0.5,
                //     ),
                //     borderRadius: BorderRadius.circular(60),
                //     border: Border.all(
                //       color: Colors.white.withValues(alpha: 0.2),
                //     ),
                //   ),
                //   // child: Image.asset(
                //   //   LOGO_PIXEL,
                //   //   height: 120,
                //   //   width: 120,
                //   //   cacheHeight: 120,
                //   //   cacheWidth: 120,
                //   // ),
                // ),
                const SizedBox(height: 20),

                // ── Titre selon le mode ─────────────────────────────────
                Text(
                  isSocial ? 'Complétez votre profil' : 'Créez votre compte',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSocial
                      ? 'Plus qu\'une étape avant de commencer !'
                      : 'Remplissez les informations ci-dessous',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      AppStepper(
                        labels: const ['Compte', 'Profil'],
                        current: controller.step.value,
                        color: Colors.white,
                        onColor: GPTheme.primaryColor,
                      ),
                      const SizedBox(height: 22),

                      // ── ÉTAPE 1 : informations du compte ──────────────
                      Visibility(
                        visible: controller.step.value == 0,
                        maintainState: true,
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            children: [
                              AppField(
                                controller: controller.nameController,
                                hint: 'Nom et prénom(s)',
                                icon: Icons.person_outline,
                                capitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez saisir votre nom complet';
                                  }
                                  if (value.trim().split(' ').length < 2) {
                                    return 'Veuillez saisir votre nom ET prénom(s)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppField(
                                controller: controller.emailController,
                                hint: 'Adresse email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                readOnly: (isSocial && !controller.canChangeMail.value),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez saisir votre email';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  ).hasMatch(value.trim())) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<Country>(
                                valueListenable: controller.selectedCountry,
                                builder: (_, country, _) => AppField(
                                  controller: controller.phoneController,
                                  hint: 'Téléphone',
                                  keyboardType: TextInputType.phone,
                                  prefix: CountryPickerWidget(
                                    selectedCountry: country,
                                    onChanged: (c) => controller.selectedCountry.value = c,
                                  ),
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    SimplePhoneFormatter(),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez saisir votre téléphone';
                                    }
                                    if (value.length < 6) return 'Numéro invalide';
                                    return null;
                                  },
                                ),
                              ),
                              if (!isSocial) ...[
                                const SizedBox(height: 16),
                                AppField(
                                  controller: controller.passwordController,
                                  hint: 'Mot de passe',
                                  icon: Icons.lock_outline,
                                  obscure: controller.isObscure.value,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez saisir un mot de passe';
                                    }
                                    if (value.length < 8) return 'Minimum 8 caractères';
                                    return null;
                                  },
                                  suffix: IconButton(
                                    onPressed: () => controller.isObscure.value = !controller.isObscure.value,
                                    icon: Icon(
                                      controller.isObscure.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── ÉTAPE 2 : profil d'audience ───────────────────
                      Visibility(
                        visible: controller.step.value == 1,
                        maintainState: true,
                        child: Form(
                          key: controller.formKey2,
                          child: AudienceFields(state: controller.audience),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Boutons ───────────────────────────────────────
                      if (controller.step.value == 0)
                        PrimaryButton(text: 'CONTINUER', callback: controller.nextStep)
                      else
                        Obx(
                          () => controller.isLoading.value
                              ? const PrimaryLoadingButton()
                              : Column(
                                  children: [
                                    PrimaryButton(
                                      text: isSocial ? 'FINALISER' : "S'INSCRIRE",
                                      callback: isSocial
                                          ? controller.completeSocialProfile
                                          : controller.register,
                                    ),
                                    TextButton.icon(
                                      onPressed: controller.previousStep,
                                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                                      label: const Text('Retour',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  ),
                ),

                // ── Social buttons (masqués en mode complétion) ───────
                if (!isSocial && controller.step.value == 0) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Ou',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => controller.isSocialLoading.value
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Column(
                            children: [
                              // ── Google
                              GoogleSignInButton(
                                onPressed: controller.loginWithGoogle,
                              ),
                              // ── Apple (bouton officiel — Guideline 4.8) ──
                              if (Platform.isIOS) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: SignInWithAppleButton(
                                    onPressed: controller.loginWithApple,
                                    text: 'Continuer avec Apple',
                                    style: SignInWithAppleButtonStyle.black,
                                    borderRadius: BorderRadius.circular(30),
                                    height: 48,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Vous avez déjà un compte ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.offNamed('/login'),
                  child: const Text(
                    'CONNECTEZ-VOUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    });
  }
}
