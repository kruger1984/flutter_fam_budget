import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';
import '../utils/talker_pod.dart';

part 'analytics_service.g.dart';

class AnalyticsService {
  AnalyticsService(this._analytics, this._talker);

  final FirebaseAnalytics _analytics;
  final Talker _talker;

  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    try {
      final nonNullableParams = parameters?.map(
            (key, value) => MapEntry(key, value ?? ''),
      );

      await _analytics.logEvent(name: name, parameters: nonNullableParams);

      _talker.debug('📊 Analytics Event: $name | Params: $nonNullableParams');
    } catch (e, st) {
      _talker.error('❌ Failed to log analytics event: $name', e, st);
    }
  }

  // Future<void> setUserId(String? id) async {
  //   await _analytics.setUserId(id: id);
  // }
}

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService(
    FirebaseAnalytics.instance,
    ref.watch(talkerProvider),
  );
}