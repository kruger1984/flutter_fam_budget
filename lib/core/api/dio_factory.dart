import 'dart:io';

import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

/// Builds a configured [Dio] for the app. Keeps routing and features out of core.
class DioFactory {
  DioFactory._();

  static Dio create({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 60),
    Future<String> Function()? getToken,
    void Function()? onUnauthorized,
    Talker? talker,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: const {
          Headers.acceptHeader: 'application/json',
          Headers.contentTypeHeader: 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (getToken != null) {
            try {
              final token = await getToken();
              if (token.isNotEmpty) {
                options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
              } else {
                talker?.warning('HTTP client: auth token is empty');
              }
            } catch (e, st) {
              talker?.handle(e, st, 'HTTP client: failed to read auth token');
            }
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(e);
        },
      ),
    );

    if (talker != null) {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseData: true,
            printResponseHeaders: false,
            printErrorData: true,
          ),
        ),
      );
    }

    return dio;
  }
}
