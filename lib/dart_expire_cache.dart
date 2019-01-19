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
class ExpireCache<K, V> {
  final Duration expireDuration;
  final Duration gcDuration;
  final Clock clock;
  Timer _expireTimer;
  Map<K, _CacheEntry<V>> _cache = Map<K, _CacheEntry<V>>();

  ExpireCache(
      {this.clock = const Clock(),
      this.expireDuration = const Duration(seconds: 60),
      this.gcDuration = const Duration(seconds: 60)});

  Future<Null> set(K key, V value) async {
    _cache[key] = _CacheEntry(value, clock.now());
    _expireTimer ??= Timer(gcDuration, _expireOutdatedEntries);
  }

  Future<Null> invalidate(K key) async {
    _cache.remove(key);
  }

  Future<Null> _expireOutdatedEntries() async {
    _cache.keys
        .where((key) =>
            clock.now().difference(_cache[key]._createTime) > expireDuration)
        .toList()
        .forEach(_cache.remove);
  }

  Future<V> get(K key) async {
    if (_cache.containsKey(key)) {
      return _cache[key]._cacheObject;
    }
    return null;
  }
}
