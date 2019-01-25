import 'package:expire_cache/expire_cache.dart';

class _SearchObjectWithMutex {
  static int cacheSetCount = 0;
  static void getInflightOrSet(
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

class _SearchObjectWithoutMutex {
  static int cacheSetCount = 0;
  static void getOrSet(
      ExpireCache<String, String> cache, String key, String value) async {
    if (await cache.get(key) != null) {
      return;
    }
    cacheSetCount++;
    await cache.set(key, value);
  }
}

void main() async {
  ExpireCache<String, String> cache = ExpireCache<String, String>();
  _SearchObjectWithMutex.getInflightOrSet(cache, 'key', 'value');
  await _SearchObjectWithMutex.getInflightOrSet(cache, 'key', 'value');
  // Cache should only be set once.
  print(
      'with mutex ${_SearchObjectWithMutex.cacheSetCount}'); // 1, set is called only once.

  cache.clear();
  _SearchObjectWithoutMutex.getOrSet(cache, 'key', 'value2');
  await _SearchObjectWithoutMutex.getOrSet(cache, 'key', 'value2');
  // Cache should only be set once.
  print(
      'without mutex ${_SearchObjectWithoutMutex.cacheSetCount}'); // 2, because the get/set pair are run at the same time, both get will get null.
}
