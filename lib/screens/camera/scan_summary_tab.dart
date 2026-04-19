import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/camera_provider.dart';

class ScanSummaryTab extends StatelessWidget {
  const ScanSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    final totalDocs = cameraProvider.documents.length;
    final totalFaces = attendanceProvider.registeredFaces.length;
    final todayAttendance = attendanceProvider.getRecordsForDate(DateTime.now()).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          context,
          title: 'Total Scanned Documents',
          value: totalDocs.toString(),
          icon: Icons.document_scanner_rounded,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          title: 'Total Registered Faces',
          value: totalFaces.toString(),
          icon: Icons.people_alt_rounded,
          color: Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          title: "Today's Attendance",
          value: todayAttendance.toString(),
          icon: Icons.fact_check_rounded,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
