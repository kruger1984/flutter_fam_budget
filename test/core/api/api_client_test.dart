import 'dart:io';

import 'package:dio/dio.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/api_exception.dart';
import 'package:family_budget/core/api/dio_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

HttpRequestMatcher _pathMatch() => const UrlRequestMatcher(matchMethod: true);

void main() {
  group('ApiClient', () {
    test('get returns response data', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      DioAdapter(dio: dio, matcher: _pathMatch())
        ..onGet('items', (server) => server.reply(200, {'items': <int>[1]}));

      final client = ApiClient(dio);
      final data = await client.get(path: 'items');
      expect(data, {'items': <int>[1]});
    });

    test('throws ApiException with server message and status from JSON body', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      DioAdapter(dio: dio, matcher: _pathMatch())
        ..onGet('fail', (server) => server.reply(422, {'message': 'bad'}));

      final client = ApiClient(dio);
      await expectLater(
        client.get(path: 'fail'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'bad')
              .having((e) => e.code, 'code', 422),
        ),
      );
    });

    test('uses error key when message is absent', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      DioAdapter(dio: dio, matcher: _pathMatch())
        ..onGet('x', (server) => server.reply(500, {'error': 'oops'}));

      final client = ApiClient(dio);
      await expectLater(
        client.get(path: 'x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'oops')),
      );
    });
  });

  group('DioFactory', () {
    test('adds Authorization bearer when getToken returns a non-empty token', () async {
      Object? seenAuth;
      final dio = DioFactory.create(
        baseUrl: 'https://example.test/api/',
        getToken: () async => 'tok',
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seenAuth = options.headers[HttpHeaders.authorizationHeader];
            return handler.next(options);
          },
        ),
      );
      DioAdapter(dio: dio, matcher: _pathMatch())
        ..onGet('me', (server) => server.reply(200, {'id': 1}));

      await ApiClient(dio).get(path: 'me');
      expect(seenAuth, 'Bearer tok');
    });

    test('invokes onUnauthorized when the server responds with 401', () async {
      var unauthorized = false;
      final dio = DioFactory.create(
        baseUrl: 'https://example.test/api/',
        onUnauthorized: () => unauthorized = true,
      );
      DioAdapter(dio: dio, matcher: _pathMatch())
        ..onGet('gate', (server) => server.reply(401, {'message': 'nope'}));

      final client = ApiClient(dio);
      await expectLater(client.get(path: 'gate'), throwsA(isA<ApiException>()));
      expect(unauthorized, isTrue);
    });
  });
}
