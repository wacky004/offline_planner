import 'package:hive/hive.dart';
import 'bible_verse.dart';

class BibleVerseAdapter extends TypeAdapter<BibleVerse> {
  @override
  final int typeId = 3;

  @override
  BibleVerse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BibleVerse(
      id: fields[0] as String,
      bookId: fields[1] as String,
      bookName: fields[2] as String,
      chapterNumber: fields[3] as int,
      verseNumber: fields[4] as int,
      verseText: fields[5] as String,
      note: fields[6] as String,
      isFavorite: fields[7] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[9] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BibleVerse obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.bookName)
      ..writeByte(3)
      ..write(obj.chapterNumber)
      ..writeByte(4)
      ..write(obj.verseNumber)
      ..writeByte(5)
      ..write(obj.verseText)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(9)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
