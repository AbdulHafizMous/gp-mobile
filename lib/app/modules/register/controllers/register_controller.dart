import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class RegisterController extends GetxController {
  //TODO: Implement RegisterController

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final isObscure = true.obs;
  final isRemember = false.obs;
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = true;
    debugPrint("Name: ${nameController.text}");
    debugPrint("Email: ${emailController.text}");
    debugPrint("Password: ${passwordController.text}");

    try {
      final response = await RequestService().post(
        '/user/register',
        data: {
          "last_name": nameController.text.split(' ')[0],
          "first_name": nameController.text.split(' ').sublist(1).join(' '),
          "email": emailController.text,
          "password": passwordController.text,
          "password_confirmation": passwordController.text,
          "terms": true,
        },
      );

      debugPrint('Data: ${response.data}');

      if (response.statusCode == 200) {
        GetStorage().write(
          'verification_code',
          response.data['verification_code'],
        );
        GetStorage().write('email', emailController.text);
        await ToastHelper.showToast(
          response.data['message'],
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }

      // Navigate to confirmation screen so user can confirm their email
      Get.offAllNamed('/confirm');
    } catch (e) {
      debugPrint("Error: ${e.toString()}");

      // Handle Dio errors with validation messages
      if (e is DioException) {
        final resp = e.response;
        if (resp != null && resp.data != null) {
          try {
            final data = resp.data;
            // If API returns errors map like { "errors": { "email": ["..."] } }
            if (data is Map &&
                data['errors'] != null &&
                data['errors'] is Map) {
              final errors = data['errors'] as Map;
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
            } else if (data is Map && data['message'] != null) {
              Get.snackbar(
                'Erreur',
                data['message'].toString(),
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
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
            debugPrint('Error parsing error response: $parseErr');
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
          "Error",
          "Une erreur est survenue, veuillez réessayer",
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
