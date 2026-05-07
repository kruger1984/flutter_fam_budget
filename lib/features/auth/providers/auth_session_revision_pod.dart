import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_session_revision_pod.g.dart';

/// Bumps when the API returns 401 so [authProvider] rebuilds from storage.
@Riverpod(keepAlive: true)
class AuthSessionRevision extends _$AuthSessionRevision {
  @override
  int build() => 0;

  void afterUnauthorized() => state = state + 1;
}
