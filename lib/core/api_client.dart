import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://api.tareeqalmajd.best/api';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 10),
    ),
  );
  static const _storage = FlutterSecureStorage();

  static void Function()? onUnauthorized;

  static const _maxRetries = 2;

  static bool _isTransient(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        final status = e.response?.statusCode;
        return status != null && status >= 500;
    }
  }

  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
            await _storage.delete(key: 'user_id');
            onUnauthorized?.call();
            return handler.next(e);
          }

          final method = e.requestOptions.method.toUpperCase();
          final attempt = (e.requestOptions.extra['retryAttempt'] as int?) ?? 0;
          if (method == 'GET' && _isTransient(e) && attempt < _maxRetries) {
            final delay = Duration(milliseconds: 500 * (1 << attempt));
            await Future.delayed(delay);
            try {
              final retryOptions = e.requestOptions
                ..extra['retryAttempt'] = attempt + 1;
              final response = await _dio.fetch(retryOptions);
              return handler.resolve(response);
            } catch (_) {}
          }

          return handler.next(e);
        },
      ),
    );
  }

  static Dio get dio => _dio;

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  static Future<void> clearUserId() async {
    await _storage.delete(key: 'user_id');
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<String> uploadFile(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post(
      '/uploads',
      data: formData,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    final url = response.data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('استجابة رفع غير صالحة من الخادم');
    }
    return url;
  }
}

abstract final class MediaUrl {
  static String get _host {
    final uri = Uri.parse(ApiClient.baseUrl);
    final portSuffix = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portSuffix';
  }

  static bool isRemote(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('/uploads/');
  }

  static String resolve(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$_host$path';
  }
}
