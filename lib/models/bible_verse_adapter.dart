import 'package:hive/hive.dart';
import 'bible_verse.dart';

class BibleVerseAdapter extends TypeAdapter<BibleVerse> {
  @override
  final int typeId = 6;

  @override
  BibleVerse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BibleVerse(
      id: fields[0] as String,
      bookId: fields[1] as String,
      chapterId: fields[2] as String,
      verseNumber: fields[3] as int,
      verseText: fields[4] as String,
      note: fields[5] as String,
      isFavorite: fields[6] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BibleVerse obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.chapterId)
      ..writeByte(3)
      ..write(obj.verseNumber)
      ..writeByte(4)
      ..write(obj.verseText)
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
