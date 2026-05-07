import 'package:family_budget/core/cache/prefs_app_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PrefsAppCache returns null for missing key', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = PrefsAppCache(prefs);

    final v = await cache.getRaw(namespace: 'n', key: 'k');
    expect(v, isNull);
  });

  test('PrefsAppCache stores and reads raw value', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = PrefsAppCache(prefs);

    await cache.putRaw(namespace: 'n', key: 'k', value: {'a': 1});
    final v = await cache.getRaw(namespace: 'n', key: 'k');
    expect(v, isA<Map>());
    expect((v as Map)['a'], 1);
  });

  test('PrefsAppCache expires by ttl', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = PrefsAppCache(prefs);

    await cache.putRaw(namespace: 'n', key: 'k', value: 'v', ttl: Duration.zero);
    final v = await cache.getRaw(namespace: 'n', key: 'k');
    expect(v, isNull);
  });

  test('PrefsAppCache clears namespace only', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = PrefsAppCache(prefs);

    await cache.putRaw(namespace: 'a', key: '1', value: 'x');
    await cache.putRaw(namespace: 'a', key: '2', value: 'y');
    await cache.putRaw(namespace: 'b', key: '1', value: 'z');

    await cache.clearNamespace('a');

    expect(await cache.getRaw(namespace: 'a', key: '1'), isNull);
    expect(await cache.getRaw(namespace: 'a', key: '2'), isNull);
    expect(await cache.getRaw(namespace: 'b', key: '1'), 'z');
  });
}

