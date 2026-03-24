import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

enum RegisterMode { normal, socialCompletion }

class RegisterController extends GetxController {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final selectedCountry = ValueNotifier<Country>(
    CountryPickerUtils.getCountryByIsoCode('BJ'),
  );

  final isObscure = true.obs;
  final isLoading = false.obs;
  final isSocialLoading = false.obs;
  final canChangeMail = false.obs;
  final formKey = GlobalKey<FormState>();
  final registerMode = RegisterMode.normal.obs;

  String? _socialToken;
  String? _socialProvider;

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _detectMode();
  }

  void _detectMode() {
    final socialName = GetStorage().read<String>('social_name');
    final socialEmail = GetStorage().read<String>('social_email');
    _socialToken = GetStorage().read<String>('social_token');
    _socialProvider = GetStorage().read<String>('social_provider');
    if (socialEmail == null || socialEmail.isEmpty) {
      canChangeMail.value = true;
    }

    debugPrint("welcome on register --- token : ${_socialToken}");

    if (_socialToken != null && _socialToken!.isNotEmpty) {
      registerMode.value = RegisterMode.socialCompletion;
      if (socialName != null) nameController.text = socialName;
      if (socialEmail != null) emailController.text = socialEmail;
      debugPrint('RegisterMode: socialCompletion ($_socialProvider)');
    } else {
      registerMode.value = RegisterMode.normal;
      debugPrint('RegisterMode: normal');
    }
  }

  bool get isSocialCompletion =>
      registerMode.value == RegisterMode.socialCompletion;

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    selectedCountry.dispose();
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REGISTER NORMAL
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
        GetStorage().write('email', emailController.text.trim());
        GetStorage().write('verification_code', '1234');
        await ToastHelper.showToast(
          'Inscription réussie ! Vérifiez votre email.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.offAllNamed('/confirm');
        return;
      }

      final nameParts = nameController.text.trim().split(' ');
      final lastName = nameParts.first;
      final firstName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final fullPhone =
          '+${selectedCountry.value.phoneCode}${phoneController.text.replaceAll(" ", "").trim()}';

      final response = await RequestService().post(
        '/auth/register',
        data: {
          'last_name': lastName,
          'first_name': firstName,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': fullPhone,
          'country_code': selectedCountry.value.isoCode,
          'password': passwordController.text,
          'password_confirmation': passwordController.text,
          'terms': true,
        },
      );

      debugPrint('Register [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 201) {
        // GetStorage().write(
        //   'verification_code',
        //   response.data['verification_code'],
        // );
        GetStorage().write('email', emailController.text.trim());

        await ToastHelper.showToast(
          response.data['message'] ?? 'Inscription réussie !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Get.offAllNamed('/confirm');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('Register error: $e');
      _showError('Une erreur inattendue est survenue, veuillez réessayer.');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPLÉTION PROFIL SOCIAL
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> completeSocialProfile() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
        _clearSocialStorage();
        GetStorage().write('token', 'Hafiz-Mock-Token');
        GetStorage().write('isLogged', true);
        await ToastHelper.showToast(
          'Profil complété ! Bienvenue',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Get.offAllNamed('/sucess-page');
        return;
      }

      final nameParts = nameController.text.trim().split(' ');
      final lastName = nameParts.first;
      final firstName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      final fullPhone =
          '+${selectedCountry.value.phoneCode}${phoneController.text.replaceAll(" ", "").trim()}';

      final response = await RequestService().post(
        '/users/update-profile',
        data: {
          'social_token': _socialToken,
          'provider': _socialProvider,
          'name': nameController.text.trim(),
          'last_name': lastName,
          'first_name': firstName,
          'phone': fullPhone,
          'country_code': selectedCountry.value.isoCode,
          'email': emailController.text.trim(),
        },
      );

      debugPrint('SocialComplete [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        // final data = response.data['data'];
        _clearSocialStorage();
        // GetStorage().write('token', data['token']);
        GetStorage().write('isLogged', true);
        // if (data['user'] != null) GetStorage().write('user', data['user']);

        await ToastHelper.showToast(
          'Profil complété ! Bienvenue',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Get.offAllNamed('/sucess-page');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('SocialComplete error: $e');
      _showError('Une erreur inattendue est survenue, veuillez réessayer.');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE LOGIN — identique au LoginController
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> loginWithGoogle() async {
    isSocialLoading.value = true;
    try {
      // ── Mock ───────────────────────────────────────────────────────────
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _handleSocialLoginResponse(
          _mockSocialResponse(provider: 'google'),
          provider: 'Google',
        );
        return;
      }

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        _showError('Google Sign-In non supporté sur cette plateforme.');
        return;
      }

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _showError('Impossible de récupérer le token Google. Réessayez.');
        return;
      }

      final response = await RequestService().post(
        '/auth/social',
        data: {'provider': 'google', 'token': idToken, 'device_name': 'mobile'},
      );

      await _handleSocialLoginResponse(
        response.data['data'],
        provider: 'Google',
      );
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          break;
        case GoogleSignInExceptionCode.clientConfigurationError:
          _showError('Erreur de configuration Google. Contactez le support.');
          break;
        default:
          _showError('La connexion avec Google a échoué. Réessayez.');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('Google login error: $e');
      _showError('La connexion avec Google a échoué. Réessayez.');
    } finally {
      isSocialLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FACEBOOK LOGIN — identique au LoginController
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> loginWithFacebook() async {
    isSocialLoading.value = true;
    try {
      // ── Mock ───────────────────────────────────────────────────────────
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _handleSocialLoginResponse(
          _mockSocialResponse(provider: 'facebook'),
          provider: 'Facebook',
        );
        return;
      }

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) return;

      if (result.status != LoginStatus.success) {
        _showError(
          result.message ?? 'La connexion Facebook a échoué. Réessayez.',
        );
        return;
      }

      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        _showError('Impossible de récupérer le token Facebook. Réessayez.');
        return;
      }

      final response = await RequestService().post(
        '/auth/social',
        data: {
          'provider': 'facebook',
          'token': accessToken.token,
          'device_name': 'mobile',
        },
      );

      await _handleSocialLoginResponse(
        response.data['data'],
        provider: 'Facebook',
      );
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('Facebook login error: $e');
      _showError('La connexion avec Facebook a échoué. Réessayez.');
    } finally {
      isSocialLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOCK SOCIAL RESPONSE
  // 🔧 Modifie ces valeurs pour tester chaque cas :
  // Cas 1 — connexion directe  : is_active: true,  is_otp_verified: true,  needs_completion: false
  // Cas 2 — complétion profil  : is_active: true,  is_otp_verified: true,  needs_completion: true
  // Cas 3 — OTP à valider      : is_active: true,  is_otp_verified: false, needs_completion: false
  // Cas 4 — compte désactivé   : is_active: false, ...
  // ══════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> _mockSocialResponse({required String provider}) {
    return {
      'token': 'Hafiz-Mock-Social-Token',
      'is_active': true,
      'is_otp_verified': true,
      'needs_completion': true, // ← change ici pour tester
      'email': 'mock.user@gmail.com',
      'name': 'Mock User',
      'social_token': 'mock-social-token-123',
      'social_provider': provider.toLowerCase(),
      'verification_code': '1234',
      'user': {'first_name': 'Mock', 'email': 'mock.user@gmail.com'},
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HANDLE SOCIAL LOGIN RESPONSE
  // Même logique que LoginController — 3 bools dans l'ordre de priorité
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _handleSocialLoginResponse(
    Map<String, dynamic> data0, {
    required String provider,
  }) async {
    debugPrint("Data Got as Response : $data0");
    var data = data0['user'];
    // Save Data
    GetStorage().write('token', data0['token']);
    // GetStorage().write('user', data);

    // ── 1. Compte désactivé ────────────────────────────────────────────────
    if (data['is_active'] == false) {
      _showError(
        'Votre compte a été désactivé. Veuillez contacter les administrateurs.',
        isWarning: true,
      );
      return;
    }

    // ── 2. Profil incomplet → reste sur register en mode complétion ────────
    if (data['needs_completion'] == true) {
      GetStorage().write('social_name', data['name'] ?? '');
      GetStorage().write('social_email', data['email'] ?? '');
      GetStorage().write(
        'social_token',
        data0['token'] ?? 'neccessary-to-trigger-completion-mode',
      );
      GetStorage().write('social_provider', provider.toLowerCase());

      // Recharge le mode sans changer de route
      _detectMode();

      await ToastHelper.showToast(
        'Complétez votre profil pour continuer.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    // ── 3. OTP non validé ──────────────────────────────────────────────────
    if (data['is_otp_verified'] == false) {
      GetStorage().write('email', data['email'] ?? '');
      if (data['verification_code'] != null) {
        GetStorage().write('verification_code', data['verification_code']);
      }
      await ToastHelper.showToast(
        'Veuillez confirmer votre compte pour continuer.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.offAllNamed('/confirm');
      });
      return;
    }

    // ── 4. Connexion réussie ───────────────────────────────────────────────
    _clearSocialStorage();
    GetStorage().write('token', data0['token']);
    GetStorage().write('isLogged', true);
    // if (data['user'] != null) GetStorage().write('user', data['user']);

    await ToastHelper.showToast(
      'Connexion réussie ! Bienvenue  ',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    Get.offAllNamed('/sucess-page');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  void _clearSocialStorage() {
    final s = GetStorage();
    s.remove('social_name');
    s.remove('social_email');
    s.remove('social_token');
    s.remove('social_provider');
  }

  void _handleDioError(DioException e) {
    debugPrint('DioException [${e.response?.statusCode}]: ${e.response?.data}');

    final resp = e.response;

    // Pas de réponse serveur (timeout, network error, etc.)
    if (resp == null) {
      _showError(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
      return;
    }

    final data = resp.data;

    // Réponse vide
    if (data == null) {
      _showError('Erreur serveur (${resp.statusCode}).');
      return;
    }

    try {
      // Data doit être un Map
      if (data is! Map) {
        _showError('Réponse serveur invalide.');
        return;
      }

      // ========== CAS 1 : Compte désactivé ==========
      if (data['is_active'] == false) {
        _showError(
          'Votre compte a été désactivé. Contactez les administrateurs.',
          isWarning: true,
        );
        return;
      }

      // ========== CAS 2 : Erreurs de validation (format API Platform) ==========
      // Format: {success: false, message: "...", data: {field: [errors]}}
      if (data['data'] != null && data['data'] is Map) {
        final errors = data['data'] as Map;
        final errorMessages = <String>[];

        errors.forEach((field, value) {
          if (value is List && value.isNotEmpty) {
            // Extraire les messages d'erreur du tableau
            errorMessages.addAll(value.map((e) => e.toString()));
          } else if (value is String) {
            errorMessages.add(value);
          }
        });

        if (errorMessages.isNotEmpty) {
          _showError(errorMessages.join('\n'));
          return;
        }
      }

      // ========== CAS 3 : Erreurs Laravel/Symfony classiques ==========
      // Format: {errors: {field: [messages]}}
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final errorMessages = errors.values
            .map((v) => v is List ? v.join(' ') : v.toString())
            .join('\n');

        if (errorMessages.isNotEmpty) {
          _showError(errorMessages);
          return;
        }
      }

      // ========== CAS 4 : Message d'erreur simple ==========
      // Format: {message: "..."}
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        _showError(data['message'].toString());
        return;
      }

      // ========== CAS 5 : Rate limiting (429) ==========
      if (resp.statusCode == 429) {
        _showError('Trop de tentatives. Veuillez patienter quelques minutes.');
        return;
      }

      // ========== CAS 6 : Erreurs HTTP standards ==========
      switch (resp.statusCode) {
        case 400:
          _showError('Requête invalide. Vérifiez les informations saisies.');
          break;
        case 401:
          _showError('Non autorisé. Veuillez vous reconnecter.');
          break;
        case 403:
          _showError(
            'Accès interdit. Vous n\'avez pas les permissions nécessaires.',
          );
          break;
        case 404:
          _showError('Ressource introuvable.');
          break;
        case 422:
          _showError('Données invalides. Vérifiez les informations saisies.');
          break;
        case 500:
          _showError('Erreur serveur. Veuillez réessayer plus tard.');
          break;
        case 503:
          _showError(
            'Service temporairement indisponible. Réessayez dans quelques instants.',
          );
          break;
        default:
          _showError(
            'Une erreur est survenue (${resp.statusCode}). Réessayez.',
          );
      }
    } catch (parseError) {
      debugPrint('Error parsing response: $parseError');
      _showError('Une erreur inattendue est survenue.');
    }
  }

  void _showError(String message, {bool isWarning = false}) {
    Get.snackbar(
      isWarning ? 'Compte désactivé' : 'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isWarning ? Colors.orange.shade700 : Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: Icon(
        isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
        color: Colors.white,
      ),
    );
  }
}
