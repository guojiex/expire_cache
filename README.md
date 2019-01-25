# expire_cache

![build status](https://travis-ci.com/guojiex/expire_cache.svg?branch=master)

A dart package provides FIFO cache and its entries will expire according to time. Also proviodes
mutex like method for search usage. Check out example/async_search_example.dart.


If you want to implement 
[SearchDelegate](https://github.com/flutter/flutter/search?q=SearchDelegate&unscoped_q=SearchDelegate) 
in your app, you will have to cache your search results. Otherwise your call to search backend might run multiple times for the same query.

See:

https://github.com/flutter/flutter/issues/11655#issuecomment-412413030

https://github.com/flutter/flutter/issues/26759

Because this is related to search, it is valuable to expire the cache after a period of time, to give user fresh search result.
And this package provide markAsInflight function, to make sure all the later get function gets the same result(if the key is the same).

## Getting Started

This project is a starting point for a Dart
[package](https://flutter.io/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

## Development

### Run test

```bash
pub run test test/
```

## Examples

find our test file to see how to use.

### Normal Cache Function

```dart
final sizeLimit = 3;
final expireDuration = Duration(seconds: 120);
ExpireCache<int, int> cache = ExpireCache<int, int>(expireDuration: expireDuration, sizeLimit: 3);
for (int i = 0; i < sizeLimit; i++) {
    cache.set(i, i);
print(cache.get(0)); // 0
```

### Mutex like usage in Search

```dart
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

```
