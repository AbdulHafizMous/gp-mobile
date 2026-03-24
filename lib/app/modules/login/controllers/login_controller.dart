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
import 'package:firebase_auth/firebase_auth.dart';

enum LoginType { phone, email }

class LoginController extends GetxController {
  // ── Controllers & Observables ──────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final loginType = ValueNotifier<LoginType>(LoginType.phone);
  final selectedCountry = ValueNotifier<Country>(
    CountryPickerUtils.getCountryByIsoCode('BJ'),
  );

  final isObscure = true.obs;
  final isRemember = false.obs;
  final isLoading = false.obs;
  final isSocialLoading = false.obs;

  final formKey = GlobalKey<FormState>();

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    loginType.dispose();
    selectedCountry.dispose();
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIN CLASSIQUE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _handleSuccessfulLogin({'token': 'Hafiz-Mock-Token'});
        return;
      }

      final Map<String, dynamic> body = {
        'password': passwordController.text.trim(),
        'country': selectedCountry.value.isoCode,
        'device_name': 'mobile',
      };

      if (loginType.value == LoginType.phone) {
        body['identifier'] =
            '+${selectedCountry.value.phoneCode}${phoneController.text.replaceAll(" ", "").trim()}';
      } else {
        body['identifier'] = emailController.text.trim();
      }
      debugPrint("body -- ${body['identifier']}");
      final response = await RequestService().post('/auth/login', data: body);
      debugPrint('Login [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200) {
        await _handleAuthResponse(response.data['data']);
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('Login error: $e');
      _showError('Une erreur inattendue est survenue, veuillez réessayer.');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE LOGIN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> loginWithGoogle() async {
    isSocialLoading.value = true;
    try {
      if (useMock) {
        //
        //
        //

        // 1. Obtient le Google ID Token
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final String? googleIdToken = googleAuth.idToken;

        if (googleIdToken == null) {
          _showError('Impossible de récupérer le token Google. Réessayez.');
          return;
        }

        // 2. Échange contre un Firebase ID Token
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleIdToken,
        );

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);

        final String? firebaseToken = await userCredential.user?.getIdToken();

        if (firebaseToken == null) {
          _showError('Impossible d\'obtenir le token Firebase. Réessayez.');
          return;
        }

        debugPrint('Firebase ID Token: $firebaseToken');
        debugPrint('Firebase ID Token length: ${firebaseToken.length}');

        //
        //
        //

        // await Future.delayed(const Duration(milliseconds: 800));
        // await _handleSocialLoginResponse(
        //   _mockSocialResponse(provider: 'google'),
        //   provider: 'Google',
        // );
        return;
      }

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        _showError('Google Sign-In non supporté sur cette plateforme.');
        return;
      }

      // 1. Obtient le Google ID Token
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? googleIdToken = googleAuth.idToken;

      if (googleIdToken == null) {
        _showError('Impossible de récupérer le token Google. Réessayez.');
        return;
      }

      // 2. Échange contre un Firebase ID Token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final String? firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        _showError('Impossible d\'obtenir le token Firebase. Réessayez.');
        return;
      }

      debugPrint('Firebase ID Token: $firebaseToken');
      debugPrint('Firebase ID Token length: ${firebaseToken.length}');

      // 3. Envoie le Firebase Token au backend
      final response = await RequestService().post(
        '/auth/social',
        data: {
          'provider': 'google',
          'token':
              firebaseToken, // ← Firebase token, vérifié par Firebase Admin SDK
          'device_name': 'mobile',
        },
      );

      await _handleSocialLoginResponse(
        response.data['data'],
        provider: 'Google',
      );
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          break;
        case GoogleSignInExceptionCode.clientConfigurationError:
          _showError('Erreur de configuration Google. Contactez le support.');
          break;
        default:
          _showError('La connexion avec Google a échoué. Réessayez.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      _showError('Erreur Firebase : ${e.message ?? 'Réessayez.'}');
    } on DioException catch (e) {
      _handleDioError(e, isSocial: true);
    } catch (e) {
      debugPrint('Google login error: $e');
      _showError('La connexion avec Google a échoué. Réessayez.');
    } finally {
      isSocialLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FACEBOOK LOGIN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> loginWithFacebook() async {
    isSocialLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _handleSocialLoginResponse(
          _mockSocialResponse(provider: 'facebook'),
          provider: 'Facebook',
        );
        return;
      }

      // 1. Obtient le Facebook Access Token
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

      final AccessToken? facebookAccessToken = result.accessToken;
      if (facebookAccessToken == null) {
        _showError('Impossible de récupérer le token Facebook. Réessayez.');
        return;
      }

      debugPrint('Facebook Access Token: ${facebookAccessToken.token}');

      // 2. Échange contre un Firebase ID Token
      final OAuthCredential credential = FacebookAuthProvider.credential(
        facebookAccessToken.token,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final String? firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        _showError('Impossible d\'obtenir le token Firebase. Réessayez.');
        return;
      }

      debugPrint('Firebase ID Token length: ${firebaseToken.length}');

      // 3. Envoie le Firebase Token au backend
      final response = await RequestService().post(
        '/auth/social',
        data: {
          'provider': 'facebook',
          'token': firebaseToken, // ← Firebase token
          'device_name': 'mobile',
        },
      );

      await _handleSocialLoginResponse(
        response.data['data'],
        provider: 'Facebook',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      // Cas spécifique : compte déjà lié à un autre provider
      if (e.code == 'account-exists-with-different-credential') {
        _showError(
          'Un compte existe déjà avec cet email via un autre fournisseur (Google, email...).',
        );
      } else {
        _showError('Erreur Firebase : ${e.message ?? 'Réessayez.'}');
      }
    } on DioException catch (e) {
      _handleDioError(e, isSocial: true);
    } catch (e) {
      debugPrint('Facebook login error: $e');
      _showError('La connexion avec Facebook a échoué. Réessayez.');
    } finally {
      isSocialLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOCK SOCIAL RESPONSE
  // Simule une réponse backend pour les parcours social en mode mock
  // Modifie ces valeurs pour tester les différents cas
  // ══════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> _mockSocialResponse({required String provider}) {
    // 🔧 Change ces valeurs pour tester chaque cas :
    // Cas 1 — connexion directe         : is_active: true,  is_otp_verified: true,  needs_completion: false
    // Cas 2 — complétion profil         : is_active: true,  is_otp_verified: true,  needs_completion: true
    // Cas 3 — OTP à valider             : is_active: true,  is_otp_verified: false, needs_completion: false
    // Cas 4 — compte désactivé          : is_active: false, is_otp_verified: true,  needs_completion: false
    return {
      'token': 'Hafiz-Mock-Social-Token',
      'is_active': true,
      'is_otp_verified': true,
      'needs_completion': false,
      'email': 'mock.user@gmail.com',
      'name': 'Mock User',
      'social_token': 'mock-social-token-123',
      'social_provider': provider.toLowerCase(),
      'verification_code': '1234',
      'user': {'first_name': 'Mock', 'email': 'mock.user@gmail.com'},
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HANDLE AUTH RESPONSE — login classique
  // Gère les 3 bools : is_active, is_otp_verified, needs_completion
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _handleAuthResponse(Map<String, dynamic> data0) async {
    debugPrint("Data Got as Response : $data0");
    var data = data0['user'];
    // ── 1. Compte désactivé par les admins ─────────────────────────────────
    if (data['is_active'] == false) {
      _showError(
        'Votre compte a été désactivé. Veuillez contacter les administrateurs.',
        isWarning: true,
      );
      return;
    }

    // ── 2. OTP non validé ──────────────────────────────────────────────────
    if (data['is_otp_verified'] == false) {
      GetStorage().write('email', data['email'] ?? emailController.text.trim());
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

    // ── 3. Connexion réussie ───────────────────────────────────────────────
    await _handleSuccessfulLogin(data0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HANDLE SOCIAL LOGIN RESPONSE
  // Même logique que _handleAuthResponse + needs_completion
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _handleSocialLoginResponse(
    Map<String, dynamic> data0, {
    required String provider,
  }) async {
    debugPrint("Data Got as Response : $data0");
    var data = data0['user'];
    // Save Data
    GetStorage().write('token', data0['token']);
    GetStorage().write('user', data);
    // ── 1. Compte désactivé ────────────────────────────────────────────────
    if (data['is_active'] == false) {
      _showError(
        'Votre compte a été désactivé. Veuillez contacter les administrateurs.',
        isWarning: true,
      );
      return;
    }

    // ── 2. Profil incomplet → complétion ───────────────────────────────────
    if (data['needs_completion'] == true) {
      GetStorage().write('social_name', data['name'] ?? '');
      GetStorage().write('social_email', data['email'] ?? '');
      GetStorage().write(
        'social_token',
        data0['token'] ?? 'neccessary-to-trigger-completion-mode',
      );
      GetStorage().write('social_provider', provider.toLowerCase());

      debugPrint(
        "going on register --- token : ${data0['token'] ?? 'neccessary-to-trigger-completion-mode'}",
      );

      await ToastHelper.showToast(
        'Bienvenue ! Complétez votre profil pour continuer.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.offAllNamed('/register');
      });
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
    await _handleSuccessfulLogin(data0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HANDLE SUCCESSFUL LOGIN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _handleSuccessfulLogin(Map<String, dynamic> data) async {
    final storage = GetStorage();
    storage.write('token', data['token']);
    storage.write('isLogged', true);
    // if (data['user'] != null) storage.write('user', data['user']);

    await ToastHelper.showToast(
      'Connexion réussie ! Bienvenue  ',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    Get.offAllNamed('/main-page');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HANDLE DIO ERROR
  // ══════════════════════════════════════════════════════════════════════════
  void _handleDioError(DioException e, {bool isSocial = false}) {
    debugPrint('DioException [${e.response?.statusCode}]: ${e.response?.data}');

    final resp = e.response;
    if (resp == null) {
      _showError(
        'Impossible de contacter le serveur. Vérifiez votre connexion Internet.',
      );
      return;
    }

    final data = resp.data;
    if (data == null) {
      _showError('Erreur serveur (${resp.statusCode}).');
      return;
    }

    try {
      // Compte non activé via champ email
      if (data is Map && data['email'] != null) {
        final msg = data['email'].toString();
        final needsConfirm =
            msg.toLowerCase().contains('valid') ||
            msg.toLowerCase().contains('confirmé') ||
            msg.toLowerCase().contains('activé');

        _showError(
          needsConfirm
              ? 'Votre compte n\'est pas encore activé. Vérifiez votre boîte mail.'
              : msg,
        );

        if (needsConfirm) {
          GetStorage().write('email', emailController.text.trim());
          Future.delayed(const Duration(milliseconds: 900), () {
            Get.offAllNamed('/confirm');
          });
        }
        return;
      }

      // is_active false dans l'erreur
      if (data is Map && data['is_active'] == false) {
        _showError(
          'Votre compte a été désactivé. Veuillez contacter les administrateurs.',
          isWarning: true,
        );
        return;
      }

      // is_otp_verified false dans l'erreur
      if (data is Map && data['is_otp_verified'] == false) {
        GetStorage().write(
          'email',
          data['email'] ?? emailController.text.trim(),
        );
        _showError('Compte non confirmé. Redirection vers la confirmation…');
        Future.delayed(const Duration(milliseconds: 900), () {
          Get.offAllNamed('/confirm');
        });
        return;
      }

      // Mot de passe incorrect
      if (data is Map && data['password'] != null) {
        _showError(data['password'].toString());
        return;
      }

      // Message générique
      if (data is Map && data['message'] != null) {
        _showError(data['message'].toString());
        return;
      }

      // Errors map
      if (data is Map && data['errors'] != null) {
        final errors = data['errors'];
        String msg;
        if (errors is Map) {
          msg = errors.values
              .map((v) => v is List ? v.join(' ') : v.toString())
              .join('\n');
        } else if (errors is List) {
          msg = errors.join('\n');
        } else {
          msg = 'Données invalides.';
        }
        _showError(msg);
        return;
      }

      if (resp.statusCode == 401) {
        _showError(
          isSocial
              ? 'Authentification sociale refusée. Réessayez.'
              : 'Identifiants incorrects. Vérifiez vos informations.',
        );
        return;
      }

      if (resp.statusCode == 429) {
        _showError('Trop de tentatives. Veuillez patienter quelques minutes.');
        return;
      }

      _showError('Une erreur est survenue (${resp.statusCode}). Réessayez.');
    } catch (parseErr) {
      debugPrint('Error parsing DioException: $parseErr');
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
