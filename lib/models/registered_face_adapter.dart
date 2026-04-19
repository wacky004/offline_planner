import 'package:hive/hive.dart';
import 'registered_face.dart';

class RegisteredFaceAdapter extends TypeAdapter<RegisteredFace> {
  @override
  final int typeId = 12;

  @override
  RegisteredFace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegisteredFace(
      id: fields[0] as String,
      name: fields[1] as String,
      imagePath: fields[2] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      totalAttendanceCount: fields[5] as int? ?? 0,
      lastSeenAt: fields[6] != null ? DateTime.fromMillisecondsSinceEpoch(fields[6] as int) : null,
    );
  }

  @override
  void write(BinaryWriter writer, RegisteredFace obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(4)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.totalAttendanceCount)
      ..writeByte(6)
      ..write(obj.lastSeenAt?.millisecondsSinceEpoch);
  }
}
