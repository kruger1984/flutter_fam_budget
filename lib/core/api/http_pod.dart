import 'package:dio/dio.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/dio_factory.dart';
import 'package:family_budget/core/config/api_config.dart';
import 'package:family_budget/core/providers/bootstrap_providers.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/auth/providers/auth_session_revision_pod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_pod.g.dart';

@Riverpod(keepAlive: true)
String apiBaseUrl(Ref ref) {
  return kApiBaseUrl;
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final talker = ref.watch(talkerProvider);
  return DioFactory.create(
    baseUrl: ref.watch(apiBaseUrlProvider),
    getToken: () async {
      final t = await ref.read(authTokenStoreProvider).readToken();
      return t ?? '';
    },
    onUnauthorized: () {
      Future<void>(() async {
        await ref.read(authTokenStoreProvider).clearToken();
        ref.read(authSessionRevisionProvider.notifier).afterUnauthorized();
      });
    },
    talker: talker,
  );
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  return ApiClient(
    ref.watch(dioProvider),
    talker: ref.watch(talkerProvider),
  );
}
