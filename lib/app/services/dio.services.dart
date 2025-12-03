import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';

class RequestService {
  static final RequestService _instance = RequestService._internal();
  factory RequestService() => _instance;

  late final Dio _dio;

  RequestService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: API_URL,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
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
          return handler.next(e);
        },
      ),
    );
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
