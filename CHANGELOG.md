## 2.0.0 - 2021.03.18

* Fix Null Safety Migration. Fix https://github.com/guojiex/expire_cache/issues/7.

## 1.0.9 - 2020.11.18

* Update _expireOutdatedEntries to be more effective(take advantage of using a LinkedHashMap).
* Now the inflight set will also expire according to expireDuration. Fixed https://github.com/guojiex/expire_cache/issues/5

## 1.0.8 - 2020.11.15

* update dart test dep version.
* fix a wrong syntax when initializing gc timer callback.

## 1.0.7 - 2020.06.27

* Update dep versions.

## 1.0.6 - 2019.01.24

* Update documents.
* Added clear method.

## 1.0.5 - 2019.01.24

* Remove blocking get and set methods.
* Add method to handle the case when get and set are fired at the same time(and cache will be set twice).

## 1.0.4 - 2019.01.24

* Add blocking get and set methods.

## 1.0.3 - 2019.01.23

* Update sdk version as dev to be compatible with flutter.


## 1.0.2 - 2019.01.20

* [Reimplement garbage collection.](https://github.com/guojiex/expire_cache/issues/2)

## 1.0.1 - 2019.01.20

* [Implement cache as FIFO and limit its size.](https://github.com/guojiex/expire_cache/issues/1)

## 0.0.1 - 2019.01.19

* A usable simple expire cache.
