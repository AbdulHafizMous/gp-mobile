import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/primary_button.dart';
import 'package:grand_public_v2/app/components/primary_loading_button.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GPTheme.primaryColor,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                LOGO_PIXEL,
                height: 150,
                width: 150,
                cacheHeight: 150,
                cacheWidth: 150,
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: controller.emailController,
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
                          hintText: "Email",
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(
                        () => TextFormField(
                          controller: controller.passwordController,
                          obscureText: controller.isObscure.value,
                          validator: (value) => value!.length < 8
                              ? "Le mot de passe doit contenir au moins 8 caractères"
                              : null,
                          decoration: InputDecoration(
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Obx(
                                () => Checkbox(
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
                              ),
                              const Text(
                                "Se souvenir de moi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w100,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Mot de passe oublié ?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      !controller.isLoading.value
                          ? PrimaryButton(
                              text: "SE CONNECTER",
                              callback: controller.login,
                            )
                          : const PrimaryLoadingButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ou continuez avec",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      debugPrint("Google");
                    },
                    child: Image.asset(GOOGLE_LOGO, height: 48, width: 48),
                  ),
                  const SizedBox(width: 25),
                  GestureDetector(
                    onTap: () {
                      debugPrint("Facebook");
                    },
                    child: Image.asset(FACEBOOK_LOGO, height: 48, width: 48),
                  ),
                  const SizedBox(height: 10),
                ],
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
                onPressed: () {
                  Get.offNamed("/register");
                },
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
