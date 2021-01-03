import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:hive/hive.dart';
import 'package:pedantic/pedantic.dart';

import 'hive_cache_object.dart';

class HiveCacheObjectProvider implements CacheInfoRepository {
  Future<Box> box;
  Box _box;

  HiveCacheObjectProvider(this.box);

  @override
  Future<bool> open() async {
    _box = await box;
    return true;
  }

  @override
  Future<dynamic> updateOrInsert(CacheObject cacheObject) async {
    return insert(cacheObject);
  }

  @override
  Future<CacheObject> insert(CacheObject cacheObject,
      {bool setTouchedToNow = true}) async {
    HiveCacheObject hiveCacheObject;
    if (cacheObject is HiveCacheObject) {
      hiveCacheObject = cacheObject;
    } else {
      hiveCacheObject = HiveCacheObject(cacheObject.url,
          key: _hiveKey(cacheObject.url),
          relativePath: cacheObject.relativePath,
          validTillMs: cacheObject.validTill.millisecondsSinceEpoch,
          touchedMs: clock.now().millisecondsSinceEpoch,
          eTag: cacheObject.eTag);
    }
    unawaited(_box.put(hiveCacheObject.key, hiveCacheObject));
    return cacheObject;
  }

  @override
  Future<CacheObject> get(String url) async {
    return _box.get(_hiveKey(url)) as CacheObject;
  }

  @override
  Future<int> delete(int id) async {
    unawaited(_box.delete(id.toString()));
    return 1;
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) async {
    unawaited(_box.deleteAll(ids.map((id) => id.toString()).toList()));
    return ids.length;
  }

  @override
  Future<int> update(CacheObject cacheObject,
      {bool setTouchedToNow = true}) async {
    unawaited(updateOrInsert(cacheObject));
    return 1;
  }

  @override
  Future<List<CacheObject>> getAllObjects() async {
    return _box.values.toList().cast<CacheObject>();
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    final dayAgo =
        clock.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

    /// all objects sorted descending by touched where touched is older than day ago
    final allObjects = (await getAllObjects())
        .where((cacheObject) =>
            (cacheObject as HiveCacheObject).touchedMs < dayAgo)
        .toList()
          ..sort((a, b) =>
              (b as HiveCacheObject).touchedMs -
              (a as HiveCacheObject).touchedMs);

    if (capacity > allObjects.length) {
      return <CacheObject>[];
    }

    return allObjects.sublist(capacity);
  }

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async {
    final then = clock.now().subtract(maxAge).millisecondsSinceEpoch;

    final allOldObjects = (await getAllObjects())
        .where(
            (cacheObject) => (cacheObject as HiveCacheObject).touchedMs < then)
        .toList();

    return allOldObjects;
  }

  @override
  Future<bool> close() async {
    // this is usually never called
    await _box.compact();
    await _box.close();
    return true;
  }

  @override
  Future<void> deleteDataFile() async {
    await _box.clear();
  }

  @override
  Future<bool> exists() async {
    return _box.isOpen;
  }
}

/// All keys have to be ASCII Strings with a max length of 255 chars or unsigned 32 bit integers
/// TODO: hashCode can change over dart versions, use MD5 instead??
String _hiveKey(String key) => key.hashCode.toString();
