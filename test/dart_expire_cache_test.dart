import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:expire_cache/dart_expire_cache.dart';

void main() {
  group("Basic Cache Test", () {
    ExpireCache<String, String> cache;
    setUp(() async {
      cache = ExpireCache<String, String>();
    });
    test('test cache set get', () async {
      cache.set('key', 'value');
      expect(await cache.get('key'), 'value');
      expect(await cache.get('not exist'), null);
    });
    test('test cache invalidate', () async {
      cache.set('key', 'value');
      cache.invalidate('key');
      expect(await cache.get('key'), null);
    });
  });
  group("Test Expire", () {
    test('test cache entry gets expired', () {
      new FakeAsync().run((async) {
        final expireDuration = Duration(seconds: 20);
        ExpireCache<String, String> cache = ExpireCache<String, String>(
            expireDuration: expireDuration, gcDuration: expireDuration);
        cache.set('key', 'value');
        cache.get('key').then((String value) => expect(value, 'value'));
        async.elapse(expireDuration);
        cache.get('key').then((String value) => expect(value, null));
      });
    });
    test('test gc duration', () {
      new FakeAsync().run((async) {
        final expireDuration = Duration(seconds: 20);
        final gcDuration = Duration(seconds: 60);
        ExpireCache<String, String> cache = ExpireCache<String, String>(
            expireDuration: expireDuration, gcDuration: gcDuration);
        cache.set('key', 'value');
        async.elapse(expireDuration);
        cache.get('key').then((String value) => expect(value, 'value'));
        async.elapse(gcDuration - expireDuration);
        cache.get('key').then((String value) => expect(value, null));
      });
    });
  });
}
