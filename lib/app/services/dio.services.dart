import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class RequestService {
  static final RequestService _instance = RequestService._internal();
  factory RequestService() => _instance;

  late final Dio _dio;

  // Endpoints où un 401 est un résultat NORMAL de la requête (identifiants
  // refusés, OTP invalide...) et ne doit donc jamais déclencher la
  // déconnexion globale + redirection. Voir onError ci-dessous.
  static const List<String> _authExemptPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/social',
    '/auth/verify-otp',
    '/auth/resend-otp',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  // Évite d'afficher/rediriger plusieurs fois si plusieurs requêtes
  // échouent en 401 en même temps (ex: appels parallèles au démarrage).
  bool _handlingSessionExpiry = false;

  RequestService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: API_URL,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          "Accept": "application/json",
          // "Content-Type": "application/json",
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = GetStorage().read("token");
          debugPrint("Token from storage: $token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          debugPrint("Requesting: ${options.uri}");
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("Response: ${response.statusCode}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("Error: ${e.message}");

          final path = e.requestOptions.path;
          final isExempt = _authExemptPaths.any((p) => path.contains(p));

          if (e.response?.statusCode == 401 && !isExempt) {
            _handleSessionExpired();
          }

          return handler.next(e);
        },
      ),
    );
  }

  /// Session expirée / token invalide sur un endpoint protégé : on nettoie
  /// le stockage local, on affiche "Vous êtes déconnecté" (jamais le brut
  /// "Erreur 401") et on renvoie vers l'écran de connexion.
  Future<void> _handleSessionExpired() async {
    if (_handlingSessionExpiry) return;
    _handlingSessionExpiry = true;
    try {
      await GetStorage().remove('token');
      await GetStorage().write('isLogged', false);

      ToastHelper.showToast(
        'Vous êtes déconnecté.',
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );

      // Get.offAllNamed('/login');
    } finally {
      // Petit délai pour absorber les autres 401 concurrents sans relancer
      // plusieurs fois la redirection.
      Future.delayed(const Duration(seconds: 2), () {
        _handlingSessionExpiry = false;
      });
    }
  }

  Dio get dio => _dio;

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(endpoint, queryParameters: queryParameters);
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.patch(endpoint, data: data, queryParameters: queryParameters);
  }

  Future<Response> head(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.head(endpoint, data: data, queryParameters: queryParameters);
  }
}
