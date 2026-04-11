import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/planner_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_goal_dialog.dart';
import '../widgets/app_drawer.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _confirmDeleteGoal(
      BuildContext context, PlannerProvider provider, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete Goal'),
        content:
            Text('Are you sure you want to delete the goal "${goal.title}"?'),
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
            const SnackBar(
                content: Text('Goal deleted'),
                duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to delete goal'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      body: Consumer2<PlannerProvider, SettingsProvider>(
        builder: (context, provider, settings, _) {
          final goals = provider.goals;
          final sym = settings.currencySymbol;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined,
                      size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No savings goals yet',
                    style: tt.titleMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to create your first goal',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            );
          }

          // Separate active and completed
          final activeGoals =
              goals.where((g) => !g.isCompleted).toList();
          final completedGoals =
              goals.where((g) => g.isCompleted).toList();

          // Overall stats
          final totalSaved =
              goals.fold(0.0, (s, g) => s + g.currentAmount);
          final totalTarget =
              goals.fold(0.0, (s, g) => s + g.targetAmount);
          final totalRemaining =
              (totalTarget - totalSaved).clamp(0.0, double.infinity);
          final overallProgress =
              totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // ── Overall summary banner ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primaryContainer, cs.secondaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: overallProgress,
                            strokeWidth: 6,
                            backgroundColor: cs.onPrimaryContainer
                                .withValues(alpha: 0.15),
                            color: overallProgress >= 1.0
                                ? Colors.green
                                : cs.primary,
                          ),
                          Text(
                            '${(overallProgress * 100).toInt()}%',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Progress',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _SummaryRow(
                            label: 'Saved',
                            value: '$sym${totalSaved.toStringAsFixed(0)}',
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(height: 2),
                          _SummaryRow(
                            label: 'Target',
                            value: '$sym${totalTarget.toStringAsFixed(0)}',
                            color: cs.onPrimaryContainer,
                          ),
                          const SizedBox(height: 2),
                          _SummaryRow(
                            label: 'Remaining',
                            value: '$sym${totalRemaining.toStringAsFixed(0)}',
                            color: totalRemaining > 0
                                ? Colors.orange.shade800
                                : Colors.green.shade700,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Quick stats chips ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Active',
                      value: '${activeGoals.length}',
                      color: cs.primary,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Completed',
                      value: '${completedGoals.length}',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Total',
                      value: '${goals.length}',
                      color: cs.tertiary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // ── Active goals ──────────────────────────────────────
              if (activeGoals.isNotEmpty) ...[
                _SectionLabel(label: 'Active Goals'),
                const SizedBox(height: 8),
                ...activeGoals.map((goal) => _GoalCard(
                      goal: goal,
                      sym: sym,
                      isDark: isDark,
                      cs: cs,
                      tt: tt,
                      onEdit: () => showDialog(
                          context: context,
                          builder: (_) =>
                              AddGoalDialog(goalToEdit: goal)),
                      onDelete: () =>
                          _confirmDeleteGoal(context, provider, goal),
                      onAddFunds: () =>
                          _showAddFundsDialog(context, goal, provider),
                    )),
              ],

              // ── Completed goals ────────────────────────────────────
              if (completedGoals.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionLabel(label: 'Completed Goals'),
                const SizedBox(height: 8),
                ...completedGoals.map((goal) => _GoalCard(
                      goal: goal,
                      sym: sym,
                      isDark: isDark,
                      cs: cs,
                      tt: tt,
                      onEdit: () => showDialog(
                          context: context,
                          builder: (_) =>
                              AddGoalDialog(goalToEdit: goal)),
                      onDelete: () =>
                          _confirmDeleteGoal(context, provider, goal),
                      onAddFunds: null,
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (_) => const AddGoalDialog());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFundsDialog(
      BuildContext context, Goal goal, PlannerProvider provider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Funds to ${goal.title}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Amount to add', hintText: '0.00'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
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

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final String sym;
  final bool isDark;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddFunds;

  const _GoalCard({
    required this.goal,
    required this.sym,
    required this.isDark,
    required this.cs,
    required this.tt,
    required this.onEdit,
    required this.onDelete,
    this.onAddFunds,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.isCompleted;
    final progress =
        goal.targetAmount > 0
            ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
            : 0.0;
    final remaining =
        (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);

    final progressColor =
        isCompleted ? Colors.green : cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────────
          Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.savings_rounded,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '🎉 Goal Reached!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.5)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Edit Goal')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete Goal')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Progress bar ──────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHighest,
              color: progressColor,
            ),
          ),
          const SizedBox(height: 4),
          // Percentage label
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Amount details ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surface.withValues(alpha: 0.5)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Saved
                Expanded(
                  child: _AmountColumn(
                    label: 'Saved',
                    value: '$sym${goal.currentAmount.toStringAsFixed(2)}',
                    color: Colors.green.shade600,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                // Target
                Expanded(
                  child: _AmountColumn(
                    label: 'Target',
                    value: '$sym${goal.targetAmount.toStringAsFixed(2)}',
                    color: cs.onSurface.withValues(alpha: 0.7),
                    icon: Icons.flag_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                // Remaining
                Expanded(
                  child: _AmountColumn(
                    label: 'Remaining',
                    value: remaining > 0
                        ? '$sym${remaining.toStringAsFixed(2)}'
                        : '$sym 0',
                    color: remaining > 0
                        ? Colors.orange.shade700
                        : Colors.green.shade600,
                    icon: Icons.hourglass_bottom_rounded,
                    bold: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Add funds button ───────────────────────────────────────
          if (onAddFunds != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddFunds,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Funds'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(
                      color: cs.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool bold;

  const _AmountColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
