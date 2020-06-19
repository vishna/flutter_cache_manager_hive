# flutter_cache_manager_hive

[![pub package](https://img.shields.io/pub/v/flutter_cache_manager_hive.svg)](https://pub.dartlang.org/packages/flutter_cache_manager_hive)

Just like [flutter_cache_manager](https://pub.dartlang.org/packages/flutter_cache_manager) but uses [hive](https://github.com/hivedb/hive) instead of sqlite to store cache object information.

**EXPERIMENTAL**

## Usage

You should register `CacheObjectAdapter` during hive initalization and pass a box to the `HiveCacheManager` - this box will be where cache information will be stored.

```dart
/// register with the number of your choice (or default)
Hive.registerAdapter(CacheObjectAdapter(typeId: 42))

/// provide the caching box
final box = Hive.openBox('image_cache_info.hive');

/// finally whenever you are using cached network image library:
CachedNetworkImage(
   imageUrl: "http://via.placeholder.com/350x150",
   placeholder: (context, url) => CircularProgressIndicator(),
   errorWidget: (context, url, error) => Icon(Icons.error),
   cacheManager: HiveCacheManager(box: box) // this is a singleton factory
)
```