import 'package:file/file.dart' as f;
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repository.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hive_cache_object_provider.dart';

class HiveCacheManager extends BaseCacheManager {
  static const key = 'libCachedImageDataHive';

  static HiveCacheManager _instance;

  factory HiveCacheManager(
      {int maxSize = 200,
      Duration maxAge = const Duration(days: 30),
      @required Future<Box> box}) {
    _instance ??= HiveCacheManager._(
        _buildCacheStore(maxSize, maxAge, box: box, storeKey: key));
    return _instance;
  }

  HiveCacheManager._(CacheStore cacheStore)
      : super(key, cacheStore: cacheStore);

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }
}

CacheStore _buildCacheStore(int maxSize, Duration maxAge,
    {@required String storeKey,
    @required Future<Box> box,
    Duration cleanupRunMinInterval = const Duration(seconds: 10)}) {
  if (kIsWeb) {
    return _createStoreForWeb(maxSize, maxAge, storeKey, box,
        cleanupRunMinInterval: cleanupRunMinInterval);
  }
  return CacheStore(_createFileDir(storeKey), storeKey, maxSize, maxAge,
      cleanupRunMinInterval: cleanupRunMinInterval);
}

Future<f.Directory> _createFileDir(String storeKey) async {
  var fs = const LocalFileSystem();
  var directory = fs.directory((await _getFilePath(storeKey)));
  await directory.create(recursive: true);
  return directory;
}

Future<String> _getFilePath(String storeKey) async {
  var directory = await getTemporaryDirectory();
  return p.join(directory.path, storeKey);
}

CacheStore _createStoreForWeb(
    int maxSize, Duration maxAge, String storeKey, Future<Box> box,
    {Duration cleanupRunMinInterval = const Duration(seconds: 10)}) {
  if (!kIsWeb) return null;
  var memDir = MemoryFileSystem().systemTempDirectory.createTemp('cache');

  return CacheStore(memDir, storeKey, maxSize, maxAge,
      cacheRepoProvider: _hiveProvider(box),
      cleanupRunMinInterval: cleanupRunMinInterval);
}

Future<CacheInfoRepository> _hiveProvider(Future<Box> box) async {
  final provider = HiveCacheObjectProvider(box);
  await provider.open();
  return provider;
}
