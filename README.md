# expire_cache

![build status](https://travis-ci.com/guojiex/expire_cache.svg?branch=master)

A dart package provides FIFO cache and its entries will expire according to time.

If you want to implement 
[SearchDelegate](https://github.com/flutter/flutter/search?q=SearchDelegate&unscoped_q=SearchDelegate) 
in your app, you will have to cache your search results if you don't want to call your search backend 
for multiple times on the same query.

See:

https://github.com/flutter/flutter/issues/11655#issuecomment-412413030

https://github.com/flutter/flutter/issues/26759

Because this is related to search, it is valuable to expire the cache after a period of time, to give user fresh search result.
And this is the goal for this package, to develop an expire by fix time cache.

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

## Example

find our test file to see how to use.

```dart
final sizeLimit = 3;
final expireDuration = Duration(seconds: 120);
ExpireCache<int, int> cache = ExpireCache<int, int>(expireDuration: expireDuration, sizeLimit: 3);
for (int i = 0; i < sizeLimit; i++) {
    cache.set(i, i);
print(cache.get(0)); // 0
```
