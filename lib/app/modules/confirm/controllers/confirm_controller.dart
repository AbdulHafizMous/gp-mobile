import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class ConfirmController extends GetxController {
  // Implement ConfirmController: verify OTP, store token and navigate to home

  Timer? timer;
  int start = 150;
  final remaingTimeInString = '02:30'.obs;
  final otpCode = ''.obs;
  final isLoading = false.obs;
  final isResendLoading = false.obs;

  void startTimer() {
    const Duration oneSec = Duration(seconds: 1);
    // initialize start to 150 seconds (2:30) if needed
    timer = Timer.periodic(oneSec, (Timer t) {
      if (start <= 0) {
        t.cancel();
      } else {
        start--;
        remaingTimeInString.value = '00:${start.toString().padLeft(2, '0')}';
        update(); // This will update the UI
      }
    });
  }

  @override
  void onClose() {
    timer?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    startTimer();
    super.onReady();
  }

  Future<void> verifyOtp(String code) async {
    if (code.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez saisir le code de confirmation',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    final email = GetStorage().read('email') ?? '';
    try {
      debugPrint('Verifying OTP for $email with code $code');

      final response = await RequestService().post(
        '/user/verify_opt',
        data: {'email': email, 'otp_code': code, 'device_name': 'mobile'},
      );

      debugPrint(
        'Verify OTP response: ${response.statusCode} ${response.data}',
      );

      if (response.statusCode == 200) {
        // API returns token on success
        final token = response.data['token'];
        if (token != null) {
          GetStorage().write('token', token);
          GetStorage().write('isLogged', true);
        }

        await ToastHelper.showToast(
          response.data['message'] ?? 'Compte vérifié avec succès',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Fetch user data to populate storage (same keys used elsewhere)
        try {
          final userResp = await RequestService().get('/user');
          debugPrint(
            'User fetch after verify: ${userResp.statusCode} ${userResp.data}',
          );
          if (userResp.statusCode == 200) {
            final data = userResp.data;
            if (data is Map) {
              GetStorage().write('username', data['first_name']);
              GetStorage().write('email', data['email']);
              // Normalize has_active_subscriptions to bool before storing
              final rawHas = data['has_active_subscriptions'];
              bool normalizedHas = false;
              if (rawHas is bool) {
                normalizedHas = rawHas;
              } else if (rawHas is num) {
                normalizedHas = rawHas != 0;
              } else if (rawHas is String) {
                final lower = rawHas.toLowerCase();
                normalizedHas =
                    (lower == '1' || lower == 'true' || lower == 'yes');
              }
              GetStorage().write('has_active_subscriptions', normalizedHas);
              debugPrint(
                'Stored has_active_subscriptions after verify: $normalizedHas (raw: $rawHas)',
              );
            }
          }
        } catch (e) {
          debugPrint('Error fetching user after verify: $e');
        }

        // Navigate to home
        Get.offAllNamed('/home');
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      if (e is DioException) {
        final resp = e.response;
        if (resp != null && resp.data != null) {
          final data = resp.data;
          try {
            if (data is Map && data['message'] != null) {
              Get.snackbar(
                'Erreur',
                data['message'].toString(),
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            } else if (data is Map && data['errors'] != null) {
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
                  'Code invalide',
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
            debugPrint('Error parsing verify error: $parseErr');
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
          'Une erreur est survenue',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> regenerateOtp() async {
    final email = GetStorage().read('email') ?? '';
    if (email.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Email introuvable',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isResendLoading.value = true;
    try {
      debugPrint('Regenerating OTP for $email');
      final response = await RequestService().post(
        '/user/regenerate_otp',
        data: {'email': email},
      );

      debugPrint(
        'Regenerate OTP response: ${response.statusCode} ${response.data}',
      );

      if (response.statusCode == 200) {
        await ToastHelper.showToast(
          response.data['message'] ?? 'Code renvoyé',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // reset timer
        start = 150;
        remaingTimeInString.value = '00:${start.toString().padLeft(2, '0')}';
        timer?.cancel();
        startTimer();
      }
    } catch (e) {
      debugPrint('Regenerate OTP error: $e');
      if (e is DioException) {
        final resp = e.response;
        if (resp != null && resp.data != null) {
          final data = resp.data;
          if (data is Map && data['message'] != null) {
            Get.snackbar(
              'Erreur',
              data['message'].toString(),
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          } else if (data is Map && data['errors'] != null) {
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
                'Impossible de renvoyer le code',
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
          'Une erreur est survenue',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isResendLoading.value = false;
    }
  }
}
