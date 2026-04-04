import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../providers/settings_provider.dart';
import '../models/entry_type.dart';
import '../widgets/top_left_menu.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const TopLeftMenu(),
        title: const Text('Monthly Summary'),
      ),
      body: Consumer2<PlannerProvider, SettingsProvider>(
        builder: (context, provider, settings, _) {
          final entries = provider.entries.where((e) => e.date.month == DateTime.now().month && e.date.year == DateTime.now().year).toList();
          
          final expenses = entries.where((e) => e.type == EntryType.expense);
          final paid = expenses.where((e) => e.isCompletedOrPaid).length;
          final unpaid = expenses.length - paid;
          final totalExp = expenses.fold(0.0, (sum, e) => sum + (e.amount ?? 0));

          final tasks = entries.where((e) => e.type == EntryType.todo);
          final completedTasks = tasks.where((e) => e.isCompletedOrPaid).length;
          final pendingTasks = tasks.length - completedTasks;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  title: const Text('Current Month Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('${settings.currencySymbol}${totalExp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.red)),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expenses Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Paid count: $paid'),
                      Text('Unpaid count: $unpaid'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tasks Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Completed count: $completedTasks'),
                      Text('Pending count: $pendingTasks'),
                      const Divider(),
                      Text('Total Tasks this month: ${tasks.length}'),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
