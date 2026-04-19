import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'camera/camera_scan_tab.dart';
import 'camera/registered_faces_tab.dart';
import 'camera/attendance_tab.dart';
import 'camera/attendance_calendar_tab.dart';
import 'camera/scan_summary_tab.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: isDark ? cs.surfaceContainerHighest : cs.primary,
          foregroundColor: isDark ? cs.onSurface : Colors.white,
          iconTheme: IconThemeData(
            color: isDark ? cs.onSurface : Colors.white,
          ),
          elevation: 0,
          title: const Text(
            'Camera',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: isDark ? cs.onSurface : Colors.white,
            unselectedLabelColor: (isDark ? cs.onSurface : Colors.white).withValues(alpha: 0.6),
            indicatorColor: isDark ? cs.onSurface : Colors.white,
            tabs: const [
              Tab(text: 'Scan Document'),
              Tab(text: 'Faces'),
              Tab(text: 'Attendance Log'),
              Tab(text: 'Calendar'),
              Tab(text: 'Summary'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CameraScanTab(),
            RegisteredFacesTab(),
            AttendanceTab(),
            AttendanceCalendarTab(),
            ScanSummaryTab(),
          ],
        ),
      ),
    );
  }
}
