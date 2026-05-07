import 'dart:io';

import 'package:dio/dio.dart';
import 'package:talker/talker.dart';

import 'api_exception.dart';

/// Thin wrapper over [Dio] matching legacy [Api] behavior: returns [Response.data]
/// and maps failures to [ApiException].
class ApiClient {
  ApiClient(this._dio, {Talker? talker}) : _talker = talker;

  final Dio _dio;
  final Talker? _talker;

  Future<dynamic> get({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _execute(() => _dio.get<dynamic>(path, queryParameters: queryParameters, options: options));
  }

  Future<dynamic> put({
    required String path,
    dynamic data,
    Options? options,
  }) {
    return _execute(() => _dio.put<dynamic>(path, data: data, options: options));
  }

  Future<dynamic> patch({
    required String path,
    dynamic data,
    Options? options,
  }) {
    return _execute(() => _dio.patch<dynamic>(path, data: data, options: options));
  }

  Future<dynamic> delete({
    required String path,
    dynamic data,
    Options? options,
  }) {
    return _execute(() => _dio.delete<dynamic>(path, data: data, options: options));
  }

  Future<dynamic> post({
    required String path,
    Map<String, dynamic>? body,
    File? file,
    String fileFieldName = 'images',
    Options? options,
  }) async {
    dynamic data = body;
    if (file != null) {
      final fileName = file.path.split(RegExp(r'[/\\]')).last;
      data = FormData.fromMap({
        ...?body,
        fileFieldName: await MultipartFile.fromFile(file.path, filename: fileName),
      });
    }
    return _execute(() => _dio.post<dynamic>(path, data: data, options: options));
  }

  Future<dynamic> _execute(Future<Response<dynamic>> Function() httpRequest) async {
    try {
      final response = await httpRequest();
      return response.data;
    } on DioException catch (e) {
      final serverMessage = _serverMessage(e);
      throw ApiException(serverMessage ?? e.message, e.response?.statusCode);
    } catch (e, st) {
      _talker?.handle(e, st, 'Unexpected API error');
      throw ApiException(e.toString(), 0);
    }
  }

  dynamic _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] ?? data['error'];
    }
    return null;
  }
}
