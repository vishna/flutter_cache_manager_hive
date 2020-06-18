import 'dart:async';

import 'package:file/file.dart' as f;
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repository.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hive_storage/cache_object_adapter.dart';
import 'hive_storage/cache_object_provider.dart';

bool _hiveInitalized = false;
Future<CacheInfoRepository> _hiveCacheInfoRepository(
    String key, Box box) async {
  if (!_hiveInitalized && box == null) {
    _hiveInitalized = true;
    await Hive.initFlutter();
    Hive.registerAdapter(CacheObjectAdapter());
  }

  final provider = HiveCacheObjectProvider('$key.hive', box: box);
  await provider.open();
  return provider;
}

class HiveCacheStore extends CacheStore {
  HiveCacheStore._(Future<f.Directory> basedir, String storeKey, int capacity,
      Duration maxAge,
      {Box box, Duration cleanupRunMinInterval = const Duration(seconds: 10)})
      : super(basedir, storeKey, capacity, maxAge,
            cacheRepoProvider: _hiveCacheInfoRepository(storeKey, box),
            cleanupRunMinInterval: cleanupRunMinInterval);

  factory HiveCacheStore.createCacheStore(int maxSize, Duration maxAge,
      {String storeKey = DefaultCacheManager.key,
      Box box,
      Duration cleanupRunMinInterval = const Duration(seconds: 10)}) {
    if (kIsWeb) {
      return _createStoreForWeb(maxSize, maxAge, storeKey, box,
          cleanupRunMinInterval: cleanupRunMinInterval);
    }
    return HiveCacheStore._(_createFileDir(storeKey), storeKey, maxSize, maxAge,
        box: box, cleanupRunMinInterval: cleanupRunMinInterval);
  }

  static Future<f.Directory> _createFileDir(String storeKey) async {
    var fs = const LocalFileSystem();
    var directory = fs.directory((await getFilePath(storeKey)));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<String> getFilePath(String storeKey) async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, storeKey);
  }

  static HiveCacheStore _createStoreForWeb(
      int maxSize, Duration maxAge, String storeKey, Box box,
      {Duration cleanupRunMinInterval = const Duration(seconds: 10)}) {
    if (!kIsWeb) return null;
    var memDir = MemoryFileSystem().systemTempDirectory.createTemp('cache');

    return HiveCacheStore._(memDir, storeKey, maxSize, maxAge,
        box: box, cleanupRunMinInterval: cleanupRunMinInterval);
  }
}
