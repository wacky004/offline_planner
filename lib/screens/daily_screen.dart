import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../providers/planner_provider.dart';
import '../widgets/add_entry_dialog.dart';
import '../widgets/entry_list_item.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, provider, _) {
        final dateStr = DateFormat.yMMMMd().format(provider.selectedDate);
        final entries = provider.selectedDateEntries;

        final todos = entries.where((e) => e.type == EntryType.todo).toList();
        final notes = entries.where((e) => e.type == EntryType.note).toList();
        final expenses = entries.where((e) => e.type == EntryType.expense).toList();

        return Scaffold(
          appBar: AppBar(title: Text(dateStr)),
          body: entries.isEmpty
            ? _buildEmptyState(context)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (todos.isNotEmpty) ...[
                    _buildSectionHeader(context, 'To-do', Icons.check_circle_outline, Colors.green),
                    ...todos.map((e) => EntryListItem(entry: e)),
                    const SizedBox(height: 16),
                  ],
                  if (notes.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Notes', Icons.note, Colors.blue),
                    ...notes.map((e) => EntryListItem(entry: e)),
                    const SizedBox(height: 16),
                  ],
                  if (expenses.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Expenses', Icons.attach_money, Colors.red),
                    ...expenses.map((e) => EntryListItem(entry: e)),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddEntryDialog(),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Theme.of(context).disabledColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No entries for this day.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap the + button to add a task, note, or expense.'),
        ],
      ),
    );
  }
}
