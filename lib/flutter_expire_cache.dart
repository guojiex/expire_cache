library flutter_expire_cache;

import 'dart:core';
import 'package:clock/clock.dart';

class _CacheEntry<V> {
  final _cacheObject;
  _CacheEntry(this._cacheObject);
}

/// A cache. Its entries will expire after a given time period.
class ExpireCache<K, V> {
  final Duration expireDuration;
  Map<K, _CacheEntry<V>> _cache = Map<K, _CacheEntry<V>>();

  ExpireCache({this.expireDuration = const Duration(seconds: 60)});

  V get(K key){
    return _cache[key]._cacheObject;
  }
}
