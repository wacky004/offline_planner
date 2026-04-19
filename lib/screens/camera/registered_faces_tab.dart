import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/camera_provider.dart';
import 'register_face_dialog.dart';

class RegisteredFacesTab extends StatelessWidget {
  const RegisteredFacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final faces = provider.registeredFaces;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: faces.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: faces.length,
              itemBuilder: (context, index) {
                final face = faces[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: FileImage(File(face.imagePath)),
                      radius: 24,
                    ),
                    title: Text(face.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Total Attendance: ${face.totalAttendanceCount}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, face, provider),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registerNewFace(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Face'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.face_retouching_natural_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No faces registered yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Register faces to start tracking attendance.'),
        ],
      ),
    );
  }

  Future<void> _registerNewFace(BuildContext context) async {
    // We can use the camera service from CameraProvider
    final cameraProvider = context.read<CameraProvider>();
    final path = await cameraProvider.scanDocument(fromCamera: true);

    if (path == null) return;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => RegisterFaceDialog(imagePath: path),
      );
    }
  }

  void _confirmDelete(BuildContext context, face, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Face?'),
        content: Text('Are you sure you want to delete ${face.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteFace(face);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
