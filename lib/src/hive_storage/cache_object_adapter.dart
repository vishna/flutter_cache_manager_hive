import 'package:clock/clock.dart';
import 'package:flutter_cache_manager_hive/src/hive_storage/cache_object.dart';
import 'package:hive/hive.dart';

class CacheObjectAdapter extends TypeAdapter<HiveCacheObject> {
  CacheObjectAdapter({int typeId = TYPE_ID}) : _typeId = typeId;
  static const TYPE_ID = 101;
  final int _typeId;

  @override
  HiveCacheObject read(BinaryReader reader) {
    return HiveCacheObject(reader.readString(),
        key: reader.readString(),
        relativePath: reader.readString(),
        validTillMs: reader.readInt() ?? 0,
        touchedMs: reader.readInt() ?? 0,
        eTag: reader.readString());
  }

  @override
  int get typeId => _typeId;

  @override
  void write(BinaryWriter writer, HiveCacheObject obj) {
    writer.writeString(obj.url);
    writer.writeString(obj.key);
    writer.writeString(obj.relativePath);
    writer.writeInt(obj.validTillMs ?? 0);
    writer.writeInt(clock.now().millisecondsSinceEpoch);
    writer.writeString(obj.eTag);
  }
}
