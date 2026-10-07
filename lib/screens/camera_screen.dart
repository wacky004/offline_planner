import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/app_drawer.dart';
import '../providers/camera_provider.dart';
import 'camera/camera_scan_tab.dart';
import 'document_viewer_screen.dart';
import 'dart:io';

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
      length: 2,
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
            labelColor: isDark ? cs.onSurface : Colors.white,
            unselectedLabelColor:
                (isDark ? cs.onSurface : Colors.white).withValues(alpha: 0.6),
            indicatorColor: isDark ? cs.onSurface : Colors.white,
            tabs: const [
              Tab(text: 'Scan Document'),
              Tab(text: 'Calendar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CameraScanTab(),
            _DocumentCalendarTab(),
          ],
        ),
      ),
    );
  }
}

/// Calendar used as a filter to track photos captured per day.
/// Photos stay saved on the local device (app docs / scanned_docs).
class _DocumentCalendarTab extends StatefulWidget {
  const _DocumentCalendarTab();

  @override
  State<_DocumentCalendarTab> createState() => _DocumentCalendarTabState();
}

class _DocumentCalendarTabState extends State<_DocumentCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, provider, _) {
        final selectedDocs = provider.documents
            .where((d) => _isSameDay(d.createdAt, _selectedDay))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) => _focusedDay = focused,
              eventLoader: (day) => provider.documents
                  .where((d) => _isSameDay(d.createdAt, day))
                  .toList(),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${selectedDocs.length} photo(s) on ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')} — saved on this device',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: selectedDocs.isEmpty
                  ? const Center(child: Text('No photos captured this day.'))
                  : ListView.builder(
                      itemCount: selectedDocs.length,
                      itemBuilder: (context, i) {
                        final doc = selectedDocs[i];
                        return ListTile(
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: File(doc.filePath).existsSync()
                                ? Image.file(File(doc.filePath),
                                    fit: BoxFit.cover)
                                : const Icon(Icons.broken_image_rounded),
                          ),
                          title: Text(doc.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(doc.filePath,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DocumentViewerScreen(document: doc)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
