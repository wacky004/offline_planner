import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/registered_face.dart';
import '../models/attendance_record.dart';
import '../services/database_service.dart';
import '../services/face_recognition_service.dart';
import '../services/camera_capture_service.dart';

class AttendanceProvider with ChangeNotifier {
  final DatabaseService _dbService;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final CameraCaptureService _cameraService = CameraCaptureService();

  List<RegisteredFace> _registeredFaces = [];
  List<AttendanceRecord> _attendanceRecords = [];

  AttendanceProvider(this._dbService) {
    _loadData();
  }

  List<RegisteredFace> get registeredFaces => _registeredFaces;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;

  void _loadData() {
    _registeredFaces = _dbService.getAllRegisteredFaces();
    _registeredFaces.sort((a, b) => a.name.compareTo(b.name));

    _attendanceRecords = _dbService.getAllAttendanceRecords();
    _attendanceRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  Future<RegisteredFace?> registerNewFace({required String name, required String imagePath}) async {
    final hasFace = await _faceService.detectFace(imagePath);
    if (!hasFace) {
      return null; // Handle error in UI
    }

    final now = DateTime.now();
    final newFace = RegisteredFace(
      id: const Uuid().v4(),
      name: name,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );

    await _dbService.addRegisteredFace(newFace);
    _loadData();
    return newFace;
  }

  bool hasAttendanceToday(String personId) {
    final now = DateTime.now();
    return _attendanceRecords.any((record) =>
        record.personId == personId &&
        record.date.year == now.year &&
        record.date.month == now.month &&
        record.date.day == now.day);
  }

  Future<String> logAttendance({
    required RegisteredFace person,
    required String imagePath,
    required String source,
  }) async {
    if (hasAttendanceToday(person.id)) {
      return 'already_logged';
    }

    final now = DateTime.now();
    final record = AttendanceRecord(
      id: const Uuid().v4(),
      personId: person.id,
      personName: person.name,
      imagePath: imagePath,
      date: DateTime(now.year, now.month, now.day),
      time: now,
      scanSource: source,
      createdAt: now,
    );

    await _dbService.addAttendanceRecord(record);

    final updatedFace = person.copyWith(
      lastSeenAt: now,
      updatedAt: now,
      totalAttendanceCount: person.totalAttendanceCount + 1,
    );
    await _dbService.updateRegisteredFace(updatedFace);

    _loadData();
    return 'success';
  }

  Future<void> deleteFace(RegisteredFace face) async {
    // Delete the image file if it exists
    await _cameraService.deleteFile(face.imagePath);

    await _dbService.deleteRegisteredFace(face.id);
    
    // Optionally delete related attendance records to avoid orphans, or keep them.
    // For now, let's keep the records but their personName will remain.
    _loadData();
  }

  Future<void> deleteAttendanceRecord(AttendanceRecord record) async {
    await _cameraService.deleteFile(record.imagePath);
    await _dbService.deleteAttendanceRecord(record.id);

    // Decrement the total count
    try {
      final face = _registeredFaces.firstWhere((f) => f.id == record.personId);
      final updatedFace = face.copyWith(
        totalAttendanceCount: (face.totalAttendanceCount > 0) ? face.totalAttendanceCount - 1 : 0,
      );
      await _dbService.updateRegisteredFace(updatedFace);
    } catch (_) {
      // Person might have been deleted
    }

    _loadData();
  }

  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    return _attendanceRecords.where((r) =>
        r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day).toList();
  }
}
