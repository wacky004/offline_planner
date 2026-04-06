import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../providers/settings_provider.dart';
import '../models/entry_type.dart';
import '../widgets/app_drawer.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Future<void> _pickMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked.month != _selectedMonth.month || picked?.year != _selectedMonth.year) {
      if (picked != null) {
        setState(() {
          _selectedMonth = DateTime(picked.year, picked.month);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _pickMonth(context),
            tooltip: 'Select Month',
          ),
        ],
      ),
      body: Consumer2<PlannerProvider, SettingsProvider>(
        builder: (context, provider, settings, _) {
          final entries = provider.entries
              .where((e) =>
                  e.date.month == _selectedMonth.month &&
                  e.date.year == _selectedMonth.year)
              .toList();

          final expenses = entries.where((e) => e.type == EntryType.expense);
          final paid = expenses.where((e) => e.isCompletedOrPaid).length;
          final unpaid = expenses.length - paid;
          final totalExp = expenses.fold(0.0, (sum, e) => sum + (e.amount ?? 0));

          final tasks = entries.where((e) => e.type == EntryType.todo);
          final completedTasks = tasks.where((e) => e.isCompletedOrPaid).length;
          final pendingTasks = tasks.length - completedTasks;

          return Column(
            children: [
              // Month Selector Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No entries for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: ListTile(
                              title: const Text('Total Expenses',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Text(
                                  '${settings.currencySymbol}${totalExp.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 20, color: Colors.red)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (expenses.isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Expenses Status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text('Paid count: $paid'),
                                    Text('Unpaid count: $unpaid'),
                                  ],
                                ),
                              ),
                            ),
                          if (expenses.isNotEmpty) const SizedBox(height: 16),
                          if (tasks.isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tasks Status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text('Completed count: $completedTasks'),
                                    Text('Pending count: $pendingTasks'),
                                    const Divider(),
                                    Text('Total Tasks this month: ${tasks.length}'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
