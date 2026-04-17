import 'package:hive/hive.dart';
import 'scanned_document.dart';

class ScannedDocumentAdapter extends TypeAdapter<ScannedDocument> {
  @override
  final int typeId = 11; // Next available typeId after 10 (WeightEntry)

  @override
  ScannedDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScannedDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      categories: (fields[5] as List?)?.cast<String>() ?? [],
      notes: fields[6] as String? ?? '',
      thumbnailPath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedDocument obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.categories)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.thumbnailPath);
  }
}
