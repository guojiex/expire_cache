import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:expire_cache/expire_cache.dart';

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
    test('test cache concurrent ', () async {
      cache.set('key', 'value');
      var res1 = cache.get('key');
      if

    });
  });
  group("Test Cache Expire", () {
    test('test cache entry gets expired', () {
      new FakeAsync().run((async) {
        final expireDuration = Duration(seconds: 20);
        ExpireCache<String, String> cache =
            ExpireCache<String, String>(expireDuration: expireDuration);
        cache.set('key', 'value');
        cache.get('key').then((String value) => expect(value, 'value'));
        async.elapse(expireDuration);
        cache.get('key').then((String value) => expect(value, null));
      });
    });
    test('test size limit', () {
      new FakeAsync().run((async) {
        final sizeLimit = 3;
        final expireDuration = Duration(seconds: 120);
        ExpireCache<int, int> cache =
            ExpireCache<int, int>(expireDuration: expireDuration, sizeLimit: 3);
        for (int i = 0; i < sizeLimit; i++) {
          cache.set(i, i).then((Null) => expect(cache.length(), i + 1));
        }
        cache
            .set(sizeLimit, sizeLimit)
            .then((Null) => expect(cache.length(), sizeLimit));
        cache.get(0).then((int value) => expect(value, null));
      });
    });
    test('test gc', () {
      new FakeAsync().run((async) {
        final sizeLimit = 3;
        final expireDuration = Duration(seconds: 10);
        final gcDuration = Duration(seconds: 20);
        ExpireCache<int, int> cache = ExpireCache<int, int>(
            expireDuration: expireDuration,
            sizeLimit: 3,
            gcDuration: gcDuration);
        cache.set(1, 1).then((Null) {
          async.elapse(gcDuration + Duration(seconds: 1));
          expect(cache.length(), 0);
        });
      });
    });
  });
}
