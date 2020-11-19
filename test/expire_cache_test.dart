import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:expire_cache/expire_cache.dart';

class _SearchObject {
  int cacheSetCount = 0;

  void getInflightOrSet(
      ExpireCache<String, String> cache, String key, String value) async {
    if (!cache.isKeyInFlightOrInCache(key)) {
      cache.markAsInFlight(key);
    } else {
      await cache.get(key);
      return;
    }
    cacheSetCount++;
    await cache.set(key, value);
  }
}

void main() {
  group("Basic Cache Test", () {
    ExpireCache<String, String> cache;
    setUp(() async {
      cache = ExpireCache<String, String>();
    });
    test('test empty cache', () async {
      expect(await cache.get('not exist'), null);
      expect(cache.length(), 0);
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
    test('test cache invalidate inflight', () async {
      cache.markAsInFlight('key');
      cache.invalidate('key');
      expect(cache.inflightLength(), 0);
      expect(await cache.get('key'), null);
    });

    /// https://github.com/flutter/flutter/issues/26759
    /// Should only set the same key once, or there is race condition.
    test('test cache concurrent write', () async {
      _SearchObject temp = _SearchObject();
      temp.getInflightOrSet(cache, 'key', 'value');
      await temp.getInflightOrSet(cache, 'key', 'value');
      // Cache should only be set once.
      expect(temp.cacheSetCount, 1);
    });
  });
  group("Test Cache Expire", () {
    test('test cache entry gets expired', () {
      new FakeAsync().run((async) {
        int expireSeconds = 20;
        final expireDuration = Duration(seconds: expireSeconds);
        final halfExpireDuration =
            Duration(seconds: (expireSeconds / 2).round());
        ExpireCache<String, String> cache =
            ExpireCache<String, String>(expireDuration: expireDuration);
        cache.set('key', 'value');
        cache.get('key').then((String value) => expect(value, 'value'));
        async.elapse(halfExpireDuration);
        cache.set('key2', 'value2');
        cache
            .get('key')
            .then((String value) => expect(value, null))
            .then((value) => expect(cache.length(), 1));
      });
    });
    test('test inflight entry gets expired', () {
      new FakeAsync().run((async) {
        final expireDuration = Duration(seconds: 10);
        final gcDuration = Duration(seconds: 15);
        ExpireCache<String, String> cache = ExpireCache<String, String>(
            expireDuration: expireDuration, gcDuration: gcDuration);
        cache
            .markAsInFlight('key')
            .then((value) => expect(cache.inflightLength(), 1));
        async.elapse(gcDuration);
        // Not sure why isKeyInFlightOrInCache will only work after a async call
        cache.get('key').then(
            (value) => expect(cache.isKeyInFlightOrInCache('key'), false));
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
        final expireDuration = Duration(seconds: 10);
        final gcDuration = Duration(seconds: 20);
        ExpireCache<int, int> cache = ExpireCache<int, int>(
            expireDuration: expireDuration, gcDuration: gcDuration);
        cache.set(1, 1).then((Null) {
          async.elapse(gcDuration + Duration(seconds: 1));
          expect(cache.length(), 0);
        });
      });
    });
  });
}
