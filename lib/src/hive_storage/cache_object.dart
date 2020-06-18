import 'package:flutter_cache_manager/src/storage/cache_object.dart';

class HiveCacheObject extends CacheObject {
  HiveCacheObject(
    String url, {
    String key,
    String relativePath,
    this.validTillMs,
    this.touchedMs,
    String eTag,
  })  : key = key ?? url,
        super(url,
            relativePath: relativePath,
            validTill: DateTime.fromMillisecondsSinceEpoch(validTillMs),
            eTag: eTag,
            id: (key ?? url).hashCode);

  /// Remove this once new version is released
  final String key;

  /// When this cached item becomes invalid
  final int validTillMs;

  /// Last time this entry was added/updated
  final int touchedMs;
}
