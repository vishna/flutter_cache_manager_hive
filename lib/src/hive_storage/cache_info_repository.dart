import 'dart:async';

import 'package:flutter_cache_manager/src/storage/cache_info_repository.dart';

abstract class HiveCacheInfoRepository extends CacheInfoRepository {
  /// Deletes a cache object by [key]
  Future<void> deleteByKey(String key);

  /// Deletes items with [keys] from the repository
  Future<void> deleteAllByKeys(Iterable<String> keys);
}
