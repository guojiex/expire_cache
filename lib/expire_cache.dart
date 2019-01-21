library expire_cache;

import 'dart:core';
import 'dart:async';
import 'dart:collection';
import 'package:clock/clock.dart';

class _CacheEntry<V> {
  final _cacheObject;
  final DateTime _createTime;
  _CacheEntry(this._cacheObject, this._createTime);
}

/// A FIFO cache. Its entries will expire after a given time period.
///
/// The cache entry will get remove when it is the first inserted entry and
/// cache reach its limited size, or when it is expired(and get is called).
class ExpireCache<K, V> {
  /// The duration between entry create and expire. Default 120 seconds
  final Duration expireDuration;
  /// The clock that uses to compute create_timestamp and expire.
  final Clock clock;
  /// The upper size limit of cache(the cache's max entry number).
  final int sizeLimit;
  /// The duration between each garbage collection. Default 180 seconds.
  final Duration gcDuration;

  Map<K, _CacheEntry<V>> _cache = LinkedHashMap<K, _CacheEntry<V>>();

  ExpireCache(
      {this.clock = const Clock(),
      this.expireDuration = const Duration(seconds: 120),
      this.sizeLimit = 100,
      this.gcDuration= const Duration(seconds: 180)})
      : assert(sizeLimit > 0) {
    Timer.periodic(gcDuration, (Timer t) => _expireOutdatedEntries);
  }

  /// Sets the value associated with [key]. The Future completes with null when
  /// the operation is complete.
  Future<Null> set(K key, V value) async {
    _cache[key] = _CacheEntry(value, clock.now());
    if (_cache.length > sizeLimit) {
      removeFirst();
    }
  }

  Future<Null> _expireOutdatedEntries() async {
    if(_cache.isEmpty){
      return;
    }
    _cache.keys.where(isCacheEntryExpired).toList().forEach(_cache.remove);
  }

  int length() => this._cache.length;

  void removeFirst() {
    final key = _cache.keys.first;
    _cache.remove(key);
  }

  /// Removes the value associated with [key]. The Future completes with null
  /// when the operation is complete.
  Future<Null> invalidate(K key) async {
    _cache.remove(key);
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
