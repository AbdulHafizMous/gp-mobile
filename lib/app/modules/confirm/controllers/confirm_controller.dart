import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class ConfirmController extends GetxController {
  // ── Observables ────────────────────────────────────────────────────────────
  final otpCode = ''.obs;
  final isLoading = false.obs;
  final isResendLoading = false.obs;
  final remainingSeconds = 60.obs;
  final canResend = false.obs;

  // ── Timer ──────────────────────────────────────────────────────────────────
  Timer? _timer;

  // ── Email masqué affiché à l'utilisateur ──────────────────────────────────
  String get maskedEmail {
    final email = GetStorage().read<String>('email') ?? '';
    if (email.isEmpty || !email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return '${name[0]}***@$domain';
    return '${name.substring(0, 3)}***@$domain';
  }

  // ── Contexte : 'register' ou 'reset_password' ─────────────────────────────
  late final String otpContext;

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void onReady() {
    super.onReady();
    // Lire le contexte stocké par ForgotPasswordController ou RegisterController
    otpContext = GetStorage().read<String>('otp_context') ?? 'register';
    debugPrint('ConfirmController context: $otpContext');
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // ── Timer (60 secondes avant de pouvoir renvoyer) ─────────────────────────
  void _startTimer() {
    remainingSeconds.value = 60;
    canResend.value = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value <= 0) {
        t.cancel();
        canResend.value = true;
      } else {
        remainingSeconds.value--;
      }
    });
  }

  String get timerLabel {
    final s = remainingSeconds.value;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VERIFY OTP
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> verifyOtp(String code) async {
    final trimmed = code.trim();
    debugPrint("Trimed $trimmed");
    if (trimmed.isEmpty || trimmed.length < 4) {
      _showError('Veuillez saisir le code complet à 4 chiffres.');
      return;
    }

    isLoading.value = true;

    try {
      // ── Mock ───────────────────────────────────────────────────────────
      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
        final stored = GetStorage().read<String>('verification_code') ?? '1234';

        if (trimmed != stored) {
          _showError('Code incorrect. En mode mock le code est : $stored');
          return;
        }

        await ToastHelper.showToast(
          'Code vérifié avec succès !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        if (otpContext == 'reset_password') {
          GetStorage().remove('otp_context');
          Get.offAllNamed('/reset-password');
        } else {
          // ← token seulement pour le register
          GetStorage().write('token', 'Hafiz-Mock-Token');
          GetStorage().write('isLogged', true);
          GetStorage().remove('otp_context');
          Get.offAllNamed('/sucess-page');
        }
        return;
      }

      // ── Réel ───────────────────────────────────────────────────────────
      final email = GetStorage().read<String>('email') ?? '';
      debugPrint('Verifying OTP for $email with code $trimmed');

      final response = await RequestService().post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': trimmed, 'device_name': 'mobile'},
      );

      debugPrint('Verify OTP [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        await ToastHelper.showToast(
          response.data['message'] ?? 'Code vérifié avec succès !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        debugPrint('Cool until Here');
        GetStorage().write('verification_code', trimmed);

        if (otpContext == 'reset_password') {
          // ← pas de token, pas de isLogged — l'user n'est pas encore connecté
          GetStorage().remove('otp_context');
          Get.offAllNamed('/reset-password');
        } else {
          // ← token seulement pour le register
          final token = response.data['data']['token'];

          debugPrint('Cool token : $token');

          if (token != null) {
            GetStorage().write('token', token);
            GetStorage().write('isLogged', true);
          }
          GetStorage().remove('otp_context');
          debugPrint('Going to success');
          Get.offAllNamed('/sucess-page');
        }
      }
    } on DioException catch (e) {
      debugPrint('Dio Exceptionr: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      _showError('Une erreur inattendue est survenue.');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REGENERATE OTP
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> regenerateOtp() async {
    if (!canResend.value) return;

    final email = GetStorage().read<String>('email') ?? '';
    if (email.isEmpty) {
      _showError('Email introuvable. Veuillez recommencer.');
      return;
    }

    isResendLoading.value = true;

    try {
      // ── Mock ───────────────────────────────────────────────────────────
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        GetStorage().write('verification_code', '1234');
        await ToastHelper.showToast(
          'Code renvoyé ! (mock: 1234)',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _startTimer();
        return;
      }

      // ── Réel ───────────────────────────────────────────────────────────
      final response = await RequestService().post(
        '/auth/resend-otp',
        data: {'email': email},
      );

      debugPrint('Regenerate OTP [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        // Sauvegarde le nouveau code si le backend le retourne
        // if (response.data['verification_code'] != null) {
        //   GetStorage().write(
        //     'verification_code',
        //     response.data['verification_code'],
        //   );
        // }

        await ToastHelper.showToast(
          response.data['message'] ?? 'Code renvoyé avec succès',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        _startTimer();
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('Regenerate OTP error: $e');
      _showError('Impossible de renvoyer le code.');
    } finally {
      isResendLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  void _handleDioError(DioException e) {
    debugPrint('DioException [${e.response?.statusCode}]: ${e.response?.data}');
    final resp = e.response;

    if (resp == null) {
      _showError(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
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
      if (data is Map && data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map) {
          final msg = errors.values
              .map((v) => v is List ? v.join(' ') : v.toString())
              .join('\n');
          _showError(msg);
          return;
        }
      }
      if (resp.statusCode == 429) {
        _showError('Trop de tentatives. Attendez quelques minutes.');
        return;
      }
      _showError('Une erreur est survenue (${resp.statusCode}).');
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
