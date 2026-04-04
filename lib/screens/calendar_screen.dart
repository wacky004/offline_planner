import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/planner_provider.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import 'daily_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Planner')),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              TableCalendar<Entry>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: provider.selectedDate,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                selectedDayPredicate: (day) => isSameDay(provider.selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  provider.setSelectedDate(selectedDay);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyScreen()),
                  );
                },
                eventLoader: (day) {
                  return provider.entries.where((e) => isSameDay(e.date, day)).toList();
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    
                    bool hasUnpaidExpense = events.any((e) => 
                      e.type == EntryType.expense && !e.isCompletedOrPaid);

                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasUnpaidExpense ? Colors.red : Colors.blue,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              const Expanded(
                child: Center(
                  child: Text('Select a date to view or add entries.'),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
