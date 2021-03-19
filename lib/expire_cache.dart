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

class _InflightEntry<V> {
  final Completer<V> _completer;
  final DateTime _createTime;

  _InflightEntry(this._completer, this._createTime);
}

/// A FIFO cache. Its entries will expire after a given time period.
///
/// The cache entry will get remove when it is the first inserted entry and
/// cache reach its limited size, or when it is expired.
///
/// You can use markAsInFlight to indicate that there will be a set call after.
/// Then before this key's corresponding value is set, all the other get to this
/// key will wait on the same [Future].
class ExpireCache<K, V> {
  /// The clock that uses to compute create_timestamp and expire.
  final Clock clock;

  /// The duration between entry create and expire. Default 120 seconds
  final Duration expireDuration;

  /// The duration between each garbage collection. Default 180 seconds.
  final Duration gcDuration;

  /// The upper size limit of [_cache](the cache's max entry number).
  final int sizeLimit;

  /// The internal cache that stores the cache entries.
  final _cache = LinkedHashMap<K, _CacheEntry<V>>();

  /// Map of outstanding set used to prevent concurrent loads of the same key.
  final _inflightSet = LinkedHashMap<K, _InflightEntry<V>>();

  ExpireCache(
      {this.clock = const Clock(),
      this.expireDuration = const Duration(seconds: 120),
      this.sizeLimit = 100,
      this.gcDuration = const Duration(seconds: 180)})
      : assert(sizeLimit > 0) {
    Timer.periodic(gcDuration, (Timer t) => _expireOutdatedEntries());
  }

  /// Sets the value associated with [key]. The Future completes with null when
  /// the operation is complete.
  ///
  /// Setting the same key should make that key the latest key in [_cache].
  Future<Null> set(K key, V value) async {
    if (_inflightSet.containsKey(key)) {
      _inflightSet[key]!._completer.complete(value);
      _inflightSet.remove(key);
    }
    // Removing the key and adding it again will make it be last in the
    // iteration order.
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    _cache[key] = _CacheEntry(value, clock.now());
    if (_cache.length > sizeLimit) {
      removeFirst();
    }
  }

  /// Expire all the outdated cache and inflight entries.
  ///
  /// [_cache] and [_inflightSet] are [LinkedHashMap], which is iterated by time
  /// order. So we just need to stop when we sees the first not expired value.
  Future<Null> _expireOutdatedEntries() async {
    _cache.keys
        .takeWhile((value) => isCacheEntryExpired(value))
        .toList()
        .forEach(_cache.remove);
    _inflightSet.keys
        .takeWhile((value) => isInflightEntryExpire(value))
        .toList()
        .forEach(_inflightSet.remove);
  }

  /// The number of entry in the cache.
  int length() => _cache.length;

  /// Returns true if there is no entry in the cache. Doesn't matter if there is
  /// any inflight entry.
  bool isEmpty() => _cache.isEmpty;

  /// The number of entry in the inflight set.
  int inflightLength() => _inflightSet.length;

  void removeFirst() {
    _cache.remove(_cache.keys.first);
  }

  /// Removes the value associated with [key]. The Future completes with null
  /// when the operation is complete.
  Future<Null> invalidate(K key) async {
    _cache.remove(key);
    _inflightSet.remove(key);
  }

  bool isCacheEntryExpired(K key) =>
      clock.now().difference(_cache[key]!._createTime) > expireDuration;

  bool isInflightEntryExpire(K key) =>
      clock.now().difference(_inflightSet[key]!._createTime) > expireDuration;

  /// Returns the value associated with [key].
  ///
  /// If the [key] is inflight, it will get the [Future] of that inflight key.
  /// Will invalidate the entry if it is expired.
  Future<V?> get(K key) async {
    if (_cache.containsKey(key) && isCacheEntryExpired(key)) {
      _cache.remove(key);
      return null;
    }
    if (_inflightSet.containsKey(key) && isInflightEntryExpire(key)) {
      _inflightSet.remove(key);
      return null;
    }
    return _cache[key]?._cacheObject ?? _inflightSet[key]?._completer.future;
  }

  /// Mark a key as inflight. Calling this again or on a already cached entry
  /// will have no effect.
  ///
  /// All the get function call on the same key after this will get the same
  /// result.
  Future<Null> markAsInFlight(K key) async {
    if (!isKeyInFlightOrInCache(key)) {
      _inflightSet[key] = _InflightEntry(new Completer(), clock.now());
    }
  }

  void clear() {
    _cache.clear();
    _inflightSet.clear();
  }

  bool containsKey(K key) => _cache.containsKey(key);

  bool isKeyInFlightOrInCache(K key) =>
      _inflightSet.containsKey(key) || _cache.containsKey(key);
}
