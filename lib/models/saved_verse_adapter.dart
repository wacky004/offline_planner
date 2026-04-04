import 'package:hive/hive.dart';
import 'saved_verse.dart';

class SavedVerseAdapter extends TypeAdapter<SavedVerse> {
  @override
  final int typeId = 3;

  @override
  SavedVerse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedVerse(
      id: fields[0] as String,
      book: fields[1] as String,
      chapter: fields[2] as String,
      verse: fields[3] as String,
      text: fields[4] as String,
      note: fields[5] as String,
      isFavorite: fields[6] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
    );
  }

  @override
  void write(BinaryWriter writer, SavedVerse obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.book)
      ..writeByte(2)
      ..write(obj.chapter)
      ..writeByte(3)
      ..write(obj.verse)
      ..writeByte(4)
      ..write(obj.text)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
