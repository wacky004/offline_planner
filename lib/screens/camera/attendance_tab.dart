import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/camera_provider.dart';
import '../../services/face_recognition_service.dart';
import 'select_person_dialog.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    // Get today's records
    final todayRecords = provider.getRecordsForDate(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: todayRecords.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: todayRecords.length,
              itemBuilder: (context, index) {
                final record = todayRecords[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: FileImage(File(record.imagePath)),
                    ),
                    title: Text(record.personName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Time: ${DateFormat('hh:mm a').format(record.time)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, record, provider),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanForAttendance(context),
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Log Attendance'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No attendance logged today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap the button below to scan a face.'),
        ],
      ),
    );
  }

  Future<void> _scanForAttendance(BuildContext context) async {
    final cameraProvider = context.read<CameraProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    if (attendanceProvider.registeredFaces.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No faces registered. Please register a face first in the Faces tab.')),
      );
      return;
    }

    final path = await cameraProvider.scanDocument(fromCamera: true);

    if (path == null) return;

    if (!context.mounted) return;

    // Show scanning dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 16),
            Text('Analyzing face...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    // Call recognition service
    final faceService = FaceRecognitionService();
    final personId = await faceService.recognizeFace(path, attendanceProvider.registeredFaces);

    if (!context.mounted) return;
    Navigator.pop(context); // close loading dialog

    if (personId != null) {
      final person = attendanceProvider.registeredFaces.firstWhere((f) => f.id == personId);
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Face Recognized'),
          content: Text('Matched with ${person.name}. Is this correct?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => SelectPersonDialog(imagePath: path),
        );
        return;
      }

      final result = await attendanceProvider.logAttendance(
        person: person,
        imagePath: path,
        source: 'Auto-Recognized',
      );

      if (!context.mounted) return;
      if (result == 'success') {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Attendance logged for ${person.name}!'), backgroundColor: Colors.green),
         );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${person.name} already logged attendance today.'), backgroundColor: Colors.orange),
         );
      }
    } else {
      // Fallback to manual selection if recognition fails
      showDialog(
        context: context,
        builder: (ctx) => SelectPersonDialog(imagePath: path),
      );
    }
  }

  void _confirmDelete(BuildContext context, record, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text('Remove this attendance record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteAttendanceRecord(record);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
