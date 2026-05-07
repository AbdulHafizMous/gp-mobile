import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sendResetCode() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      // ── Mock ─────────────────────────────────────────────────────────────
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        GetStorage().write('email', emailController.text.trim());
        GetStorage().write('verification_code', '1234');
        GetStorage().write('otp_context', 'reset_password'); // ← flag contexte
        await ToastHelper.showToast(
          'Code envoyé ! (mock: 1234)',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.offAllNamed('/confirm');
        return;
      }

      // ── Réel ──────────────────────────────────────────────────────────────
      final response = await RequestService().post(
        '/auth/forgot-password',
        data: {'email': emailController.text.trim()},
      );

      debugPrint('ForgotPassword [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        GetStorage().write('email', emailController.text.trim());
        GetStorage().write('otp_context', 'reset_password'); // ← flag contexte

        // if (response.data['verification_code'] != null) {
        //   GetStorage().write(
        //     'verification_code',
        //     response.data['verification_code'],
        //   );
        // }

        await ToastHelper.showToast(
          response.data['message'] ?? 'Code envoyé sur votre email.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Get.offAllNamed('/confirm');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('ForgotPassword error: $e');
      _showError('Une erreur inattendue est survenue, veuillez réessayer.');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleDioError(DioException e) {
    final resp = e.response;
    if (resp == null) {
      _showError('Impossible de contacter le serveur. Vérifiez votre connexion.');
      return;
    }
    final data = resp.data;
    if (data == null) {
      _showError('Erreur serveur (${resp.statusCode}).');
      return;
    }
    try {
      if (data is Map && data['message'] != null) {
        _showError(data['message'].toString());
        return;
      }
      if (data is Map && data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        _showError(
          errors.values
              .map((v) => v is List ? v.join(' ') : v.toString())
              .join('\n'),
        );
        return;
      }
      if (resp.statusCode == 404) {
        _showError('Aucun compte trouvé avec cet email.');
        return;
      }
      if (resp.statusCode == 429) {
        _showError('Trop de tentatives. Veuillez patienter quelques minutes.');
        return;
      }
      _showError('Une erreur est survenue (${resp.statusCode}). Réessayez.');
    } catch (_) {
      _showError('Une erreur inattendue est survenue.');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }
}