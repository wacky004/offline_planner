import 'package:hive/hive.dart';
import 'attendance_record.dart';

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 13;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      id: fields[0] as String,
      personId: fields[1] as String,
      personName: fields[2] as String,
      imagePath: fields[3] as String,
      date: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      time: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      status: fields[6] as String,
      scanSource: fields[7] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personId)
      ..writeByte(2)
      ..write(obj.personName)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.time.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.scanSource)
      ..writeByte(8)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }
}
