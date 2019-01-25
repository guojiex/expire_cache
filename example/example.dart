import 'package:expire_cache/expire_cache.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  new FakeAsync().run((async) {
    final sizeLimit = 3;
    final expireDuration = Duration(seconds: 120);
    ExpireCache<int, int> cache =
        ExpireCache<int, int>(expireDuration: expireDuration, sizeLimit: 3);
    for (int i = 0; i < sizeLimit; i++) {
      // 0, 1, 2
      cache.set(i, i);
    }
    cache.set(sizeLimit, sizeLimit);
    print(cache.length()); // size is 3
    cache.set(sizeLimit + 1, sizeLimit + 1);
    print(cache.length()); // size is still 3
    async.elapse(Duration(seconds: 160));
    for (int i = 0; i < sizeLimit; i++) {
      // 0, 1, 2
      cache.get(i);
    }
    print(cache.length()); // size is 3
  });
}
