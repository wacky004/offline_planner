import 'package:hive/hive.dart';
import 'song.dart';

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 7;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      durationMs: fields[3] as int?,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(5)
      //
      ..writeByte(0)
      ..write(obj.id)
      //
      ..writeByte(1)
      ..write(obj.title)
      //
      ..writeByte(2)
      ..write(obj.filePath)
      //
      ..writeByte(3)
      ..write(obj.durationMs)
      //
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
