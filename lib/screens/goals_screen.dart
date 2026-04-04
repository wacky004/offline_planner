import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/planner_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_goal_dialog.dart';
import '../widgets/app_drawer.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _confirmDeleteGoal(BuildContext context, PlannerProvider provider, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete Goal'),
        content: Text('Are you sure you want to delete the goal "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      try {
        await provider.deleteGoal(goal.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted'), duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete goal'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      body: Consumer2<PlannerProvider, SettingsProvider>(
        builder: (context, provider, settings, _) {
          final goals = provider.goals;

          if (goals.isEmpty) {
            return const Center(child: Text('No savings goals yet. Create one!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
              final isCompleted = goal.isCompleted;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          PopupMenuButton(
                            onSelected: (val) {
                              if (val == 'edit') {
                                showDialog(context: context, builder: (_) => AddGoalDialog(goalToEdit: goal));
                              } else if (val == 'delete') {
                                _confirmDeleteGoal(context, provider, goal);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Goal')),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${settings.currencySymbol}${goal.currentAmount.toStringAsFixed(2)}'),
                          Text('${settings.currencySymbol}${goal.targetAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 16),
                      if (!isCompleted)
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddFundsDialog(context, goal, provider),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Funds'),
                          ),
                        )
                      else
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            backgroundColor: Colors.green,
                            label: Text('Goal Reached!', style: TextStyle(color: Colors.white)),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddGoalDialog());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, Goal goal, PlannerProvider provider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Funds to ${goal.title}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount to add', hintText: '0.00'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val > 0) {
                provider.addFundsToGoal(goal, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
}
