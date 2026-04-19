import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_record.dart';

class AttendanceCalendarTab extends StatefulWidget {
  const AttendanceCalendarTab({super.key});

  @override
  State<AttendanceCalendarTab> createState() => _AttendanceCalendarTabState();
}

class _AttendanceCalendarTabState extends State<AttendanceCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final cs = Theme.of(context).colorScheme;
    
    // Filter records for the selected day
    final selectedRecords = _selectedDay != null 
      ? provider.getRecordsForDate(_selectedDay!) 
      : <AttendanceRecord>[];

    return Column(
      children: [
        TableCalendar<AttendanceRecord>(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            return provider.getRecordsForDate(day);
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: selectedRecords.isEmpty
              ? const Center(child: Text('No attendance for this date.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedRecords.length,
                  itemBuilder: (context, index) {
                    final record = selectedRecords[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: FileImage(File(record.imagePath)),
                        ),
                        title: Text(record.personName),
                        subtitle: Text('Time: ${DateFormat('hh:mm a').format(record.time)}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
