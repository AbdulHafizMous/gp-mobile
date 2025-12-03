import 'package:flutter/material.dart';
// fluttertoast usage wrapped by ToastHelper to avoid MissingPluginException on some platforms
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:dio/dio.dart';

class LoginController extends GetxController {
  //TODO: Implement LoginController

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final isObscure = true.obs;
  final isRemember = false.obs;
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = true;

    try {
      final response = await RequestService().post(
        '/user/login',
        data: {
          "email": emailController.text,
          "password": passwordController.text,
          "device_name": "mobile",
        },
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response data: ${response.data}');

      if (response.statusCode == 200) {
        GetStorage().write('token', response.data['token']);
        GetStorage().write('isLogged', true);
        await ToastHelper.showToast(
          'Connexion réussie',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.offAllNamed('/home');
      }
    } catch (e) {
      debugPrint('Login error: $e');

      if (e is DioException) {
        final resp = e.response;
        if (resp != null && resp.data != null) {
          final data = resp.data;
          try {
            // Case: { status: 400, password: "..." }
            if (data is Map && data['password'] != null) {
              Get.snackbar(
                'Erreur',
                data['password'].toString(),
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
            // Case: { status: 400, email: "Vous n'avez pas encore validé votre compte." }
            else if (data is Map && data['email'] != null) {
              final msg = data['email'].toString();
              Get.snackbar(
                'Erreur',
                msg,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );

              // If message indicates email not validated, redirect to confirm
              if (msg.toLowerCase().contains('valid') ||
                  msg.toLowerCase().contains('validé')) {
                // store email to allow confirm screen to prefill
                GetStorage().write('email', emailController.text);
                Future.delayed(const Duration(milliseconds: 700), () {
                  Get.offAllNamed('/confirm');
                });
              }
            }
            // Case: validation errors map like { errors: { email: [..] } }
            else if (data is Map && data['errors'] != null) {
              final errors = data['errors'];
              if (errors is Map) {
                final msgs = errors.values
                    .map((v) {
                      if (v is List) return v.join(' ');
                      return v.toString();
                    })
                    .join('\n');

                Get.snackbar(
                  'Erreur',
                  msgs,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } else if (errors is List) {
                Get.snackbar(
                  'Erreur',
                  errors.join('\n'),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Erreur',
                  'Données invalides',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            } else {
              Get.snackbar(
                'Erreur',
                'Une erreur est survenue',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          } catch (parseErr) {
            debugPrint('Error parsing login error response: $parseErr');
            Get.snackbar(
              'Erreur',
              'Une erreur est survenue',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          Get.snackbar(
            'Erreur',
            'Erreur réseau ou serveur',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Erreur',
          'Une erreur est survenue, veuillez réessayer',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
