library expire_cache;

import 'dart:core';
import 'dart:async';
import 'package:clock/clock.dart';

class _CacheEntry<V> {
  final _cacheObject;
  final DateTime _createTime;
  _CacheEntry(this._cacheObject, this._createTime);
}

/// A cache. Its entries will expire after a given time period.
///
/// The cache entry will get remove either when Garbage Collection(GC), or a get
/// function is called after it expire(but before GC).
class ExpireCache<K, V> {
  /// The duration between entry create and expire. Default 120 seconds
  final Duration expireDuration;

  /// The duration between each garbage collection. Default 180 seconds.
  final Duration gcDuration;

  /// The clock that uses to compute create_timestamp and expire.
  final Clock clock;
  Timer _expireTimer;
  Map<K, _CacheEntry<V>> _cache = Map<K, _CacheEntry<V>>();

  ExpireCache(
      {this.clock = const Clock(),
      this.expireDuration = const Duration(seconds: 120),
      this.gcDuration = const Duration(seconds: 180)});

  /// Sets the value associated with [key]. The Future completes with null when
  /// the operation is complete.
  Future<Null> set(K key, V value) async {
    _cache[key] = _CacheEntry(value, clock.now());
    _expireTimer ??= Timer(gcDuration, _expireOutdatedEntries);
  }

  /// Removes the value associated with [key]. The Future completes with null
  /// when the operation is complete.
  Future<Null> invalidate(K key) async {
    _cache.remove(key);
  }

  Future<Null> _expireOutdatedEntries() async {
    _cache.keys.where(isCacheEntryExpired).toList().forEach(_cache.remove);
  }

  bool isCacheEntryExpired(K key) =>
      clock.now().difference(_cache[key]._createTime) > expireDuration;

  /// Returns the value associated with [key].
  Future<V> get(K key) async {
    if (_cache.containsKey(key) && isCacheEntryExpired(key)) {
      invalidate(key);
      return null;
    }
    if (_cache.containsKey(key)) {
      return _cache[key]._cacheObject;
    }
    return null;
  }
}
