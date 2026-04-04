import 'package:hive/hive.dart';
import 'bible_book.dart';

class BibleBookAdapter extends TypeAdapter<BibleBook> {
  @override
  final int typeId = 4;

  @override
  BibleBook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BibleBook(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BibleBook obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
