import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

import 'hive_cache_object_provider.dart';

class HiveCacheManager extends CacheManager {
  static const key = 'libCachedImageDataHive';

  static HiveCacheManager _instance;

  factory HiveCacheManager({
    @required Future<Box> box,
    int maxSize = 200,
    Duration maxAge = const Duration(days: 30),
  }) {
    _instance ??= HiveCacheManager._(
      Config(
        key,
        stalePeriod: maxAge,
        maxNrOfCacheObjects: maxSize,
        repo: HiveCacheObjectProvider(box),
      ),
    );
    return _instance;
  }

  HiveCacheManager._(Config config) : super(config);
}
