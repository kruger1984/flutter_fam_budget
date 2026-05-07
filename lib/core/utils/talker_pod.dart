import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'talker_pod.g.dart';

/// Global app logger (Talker). Use this instead of [print] / [debugPrint].
@Riverpod(keepAlive: true)
Talker talker(Ref ref) {
  return Talker(
    settings: TalkerSettings(
      titles: {
        TalkerKey.error: 'ERROR',
        TalkerKey.exception: 'CRITICAL',
        TalkerKey.info: 'INFO',
        TalkerKey.debug: 'DEBUG',
        TalkerKey.warning: 'WARNING',
        TalkerKey.verbose: 'VERBOSE',
      },
    ),
  );
}
