import 'package:hive/hive.dart';

import 'hive_cache_object.dart';

class CacheObjectAdapter extends TypeAdapter<HiveCacheObject> {
  CacheObjectAdapter({int typeId = TYPE_ID}) : _typeId = typeId;
  static const TYPE_ID = 101;
  final int _typeId;

  @override
  HiveCacheObject read(BinaryReader reader) {
    return HiveCacheObject.fromHiveMap(reader.readMap());
  }

  @override
  int get typeId => _typeId;

  @override
  void write(BinaryWriter writer, HiveCacheObject obj) {
    writer.writeMap(obj.toMap());
  }
}
