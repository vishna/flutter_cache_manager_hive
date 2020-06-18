import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager_hive/src/hive_cache_store.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef BoxOpener = Future<Box> Function();

class HiveCacheManager extends BaseCacheManager {
  static const key = 'libCachedImageDataHive';

  static HiveCacheManager _instance;

  factory HiveCacheManager(
      {int maxSize = 200,
      Duration maxAge = const Duration(days: 30),
      @required BoxOpener boxOpener}) {
    _instance ??= HiveCacheManager._(
        HiveCacheStore.createCacheStore(maxSize, maxAge, boxOpener: boxOpener));
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
