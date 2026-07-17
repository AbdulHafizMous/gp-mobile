import 'dart:io' show Platform;

import 'package:country_pickers/country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/country_picker.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/components/primary_loading_button.dart';
import 'package:grand_public_v2/app/components/toogle_tab.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/shared/widgets/social_buttons.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
// import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../controllers/login_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────
// Login View
// ─────────────────────────────────────────────
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 20),
              Image.asset(
                LOGO_PIXEL,
                height: 120,
                width: 120,
                cacheHeight: 120,
                cacheWidth: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                "Connectez-vous à votre compte",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),

              // ── Toggle Téléphone / Email ──────────────────────────────
              ValueListenableBuilder<LoginType>(
                valueListenable: controller.loginType,
                builder: (_, type, _) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            /// Sliding highlight
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                              alignment: type == LoginType.phone
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                width: constraints.maxWidth / 2,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),

                            /// Tabs
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () => controller.loginType.value =
                                        LoginType.phone,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      // color: Colors.green,
                                      child: ToggleTab(
                                        label: "Par Téléphone",
                                        icon: Icons.phone_outlined,
                                        isActive: type == LoginType.phone,
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () => controller.loginType.value =
                                        LoginType.email,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      // color: Colors.yellow,
                                      child: ToggleTab(
                                        label: "Par Mail",
                                        icon: Icons.mail_outline,
                                        isActive: type == LoginType.email,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),

              // ── Form ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      // ── Phone field OR Email field ──────────────────
                      ValueListenableBuilder<LoginType>(
                        valueListenable: controller.loginType,
                        builder: (_, type, _) {
                          if (type == LoginType.phone) {
                            // Phone field with country picker
                            return ValueListenableBuilder<Country>(
                              valueListenable: controller.selectedCountry,
                              builder: (_, country, _) {
                                return Container(
                                  constraints: BoxConstraints(minHeight: 50),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Country picker
                                      // CountryPickerWidget(
                                      //   selectedCountry: country,
                                      //   onChanged: (c) =>
                                      //       controller.selectedCountry.value =
                                      //           c,
                                      // ),
                                      // Phone number input
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              controller.phoneController,
                                          keyboardType: TextInputType.phone,
                                          style: TextStyle(
                                            color: context.isDark
                                                ? Colors.black
                                                : null,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            SimplePhoneFormatter(),
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Veuillez saisir votre téléphone";
                                            }
                                            if (value.length < 6) {
                                              return "Numéro invalide";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            hintText: "Téléphone",
                                            prefixIcon: CountryPickerWidget(
                                              selectedCountry: country,
                                              onChanged: (c) =>
                                                  controller
                                                          .selectedCountry
                                                          .value =
                                                      c,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    right: Radius.circular(30),
                                                    left: Radius.circular(30),
                                                  ),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    right: Radius.circular(30),
                                                    left: Radius.circular(30),
                                                  ),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    right: Radius.circular(30),
                                                    left: Radius.circular(30),
                                                  ),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else {
                            // Email field
                            return Container(
                              constraints: BoxConstraints(minHeight: 50),
                              child: TextFormField(
                                controller: controller.emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  color: context.isDark ? Colors.black : null,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Veuillez saisir votre email";
                                  }
                                  if (!RegExp(
                                    r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                  ).hasMatch(value)) {
                                    return "Veuillez saisir un email valide";
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  hintText: "Adresse email",
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Password ──────────────────────────────────
                      Obx(
                        () => Container(
                          constraints: BoxConstraints(minHeight: 50),
                          child: TextFormField(
                            controller: controller.passwordController,
                            obscureText: controller.isObscure.value,
                            style: TextStyle(
                              color: context.isDark ? Colors.black : null,
                            ),
                            validator: (value) => value!.isEmpty
                                ? "Veuillez renseigner le mot de passe"
                                : null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              hintText: "Mot de passe",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  controller.isObscure.value =
                                      !controller.isObscure.value;
                                },
                                icon: Icon(
                                  controller.isObscure.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Remember me + Forgot password ────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(
                              () => InkWell(
                                onTap: () {
                                  controller.isRemember.value =
                                      !controller.isRemember.value;
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      checkColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        side: BorderSide(
                                          style: BorderStyle.solid,
                                          color: Colors.white,
                                        ),
                                      ),
                                      value: controller.isRemember.value,
                                      onChanged: (value) {
                                        controller.isRemember.value = value!;
                                      },
                                    ),
                                    const Text(
                                      "Se souvenir de moi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                Get.offAllNamed('/forgot-password');
                              },
                              child: const Text(
                                "Mot de passe oublié ?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Submit button ─────────────────────────────
                      Obx(
                        () =>
                            (!controller.isLoading.value &&
                                !controller.isSocialLoading.value)
                            ? PrimaryButton(
                                text: "SE CONNECTER",
                                callback: () => controller.login(),
                              )
                            : const PrimaryLoadingButton(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Ou",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () => controller.isSocialLoading.value
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Column(
                          children: [
                            // ── Google
                            GoogleSignInButton(
                              onPressed: () => controller.loginWithGoogle(),
                            ),

                            // ── Apple (bouton officiel — Guideline 4.8) ──
                            if (Platform.isIOS) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: SignInWithAppleButton(
                                  onPressed: () => controller.loginWithApple(),
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
              ),
              const SizedBox(height: 10),
              const Text(
                "Vous n'avez pas de compte ?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.offNamed("/register"),
                child: const Text(
                  "INSCRIVEZ-VOUS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
