import 'package:hive/hive.dart';
import 'bible_chapter.dart';

class BibleChapterAdapter extends TypeAdapter<BibleChapter> {
  @override
  final int typeId = 5;

  @override
  BibleChapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BibleChapter(
      id: fields[0] as String,
      bookId: fields[1] as String,
      chapterTitle: fields[2] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
    );
  }

  @override
  void write(BinaryWriter writer, BibleChapter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.chapterTitle)
      ..writeByte(3)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
