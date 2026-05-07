import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class ResetPasswordController extends GetxController {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isObscureNew = true.obs;
  final isObscureConfirm = true.obs;
  final isLoading = false.obs;

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      // ── Mock ─────────────────────────────────────────────────────────────
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        await ToastHelper.showToast(
          'Mot de passe réinitialisé avec succès !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.offAllNamed('/login');
        return;
      }

      // ── Réel ──────────────────────────────────────────────────────────────
      final email = GetStorage().read<String>('email') ?? '';
      final otpCode = GetStorage().read<String>('verification_code') ?? '';

      final response = await RequestService().post(
        '/auth/reset-password',
        data: {
          'identifier': email,
          'otp': otpCode,
          'new_password': passwordController.text,
          'new_password_confirmation': confirmController.text,
        },
      );

      debugPrint('ResetPassword [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        // Nettoie le storage lié au reset
        GetStorage().remove('verification_code');
        GetStorage().remove('otp_context');

        await ToastHelper.showToast(
          response.data['message'] ??
              'Mot de passe réinitialisé avec succès !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Get.offAllNamed('/login');
      }
          } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('ResetPassword error: $e');
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
      if (resp.statusCode == 422) {
        _showError('Le code est invalide ou expiré. Recommencez.');
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