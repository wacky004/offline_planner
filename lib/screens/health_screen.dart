import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/health_provider.dart';
import '../widgets/app_drawer.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Health Tracker')),
      body: Consumer<HealthProvider>(
        builder: (context, health, _) {
          final cs = Theme.of(context).colorScheme;
          final tt = Theme.of(context).textTheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ─── Steps Overview ──────────────────────────────────────
              _StepCircleCard(health: health, cs: cs, tt: tt, isDark: isDark),
              const SizedBox(height: 16),

              // ─── Weekly Steps Bar Chart ──────────────────────────────
              _SectionLabel(label: 'Weekly Steps'),
              const SizedBox(height: 8),
              _WeeklyStepsChart(
                  data: health.last7DaysSteps,
                  goal: health.stepGoal,
                  cs: cs,
                  isDark: isDark),
              const SizedBox(height: 4),
              _WeeklyStatsRow(health: health, cs: cs, tt: tt, isDark: isDark),
              const SizedBox(height: 20),

              // ─── Weight Tracker ──────────────────────────────────────
              _SectionLabel(label: 'Weight Tracker'),
              const SizedBox(height: 8),
              _WeightCard(health: health, cs: cs, tt: tt, isDark: isDark),
              const SizedBox(height: 20),

              // ─── Insights ─────────────────────────────────────────────
              _SectionLabel(label: 'Insights'),
              const SizedBox(height: 8),
              ...health.insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _InsightCard(
                        text: insight, cs: cs, isDark: isDark),
                  )),
              const SizedBox(height: 20),

              // ─── Health Settings ──────────────────────────────────────
              _SectionLabel(label: 'Settings'),
              const SizedBox(height: 8),
              _HealthSettingsCard(health: health, cs: cs, tt: tt, isDark: isDark),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<HealthProvider>(
        builder: (context, health, _) => FloatingActionButton(
          onPressed: () => _showAddMenu(context, health),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context, HealthProvider health) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Add Health Data',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.directions_walk, color: Colors.green),
              title: const Text('Log Steps Manually'),
              onTap: () {
                Navigator.pop(ctx);
                _showManualStepDialog(context, health);
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined,
                  color: Colors.blue),
              title: const Text('Log Weight'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddWeightDialog(context, health);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManualStepDialog(BuildContext context, HealthProvider health) {
    final controller =
        TextEditingController(text: health.liveSteps.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Today\'s Steps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'Steps', hintText: '0'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              if (val >= 0) {
                health.setTodaySteps(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, HealthProvider health) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Weight (kg)', hintText: '70.5'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                health.addWeightEntry(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP CIRCLE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StepCircleCard extends StatelessWidget {
  final HealthProvider health;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isDark;

  const _StepCircleCard({
    required this.health,
    required this.cs,
    required this.tt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = health.todayProgress.clamp(0.0, 1.0);
    final goalReached = health.liveSteps >= health.stepGoal;
    final progressColor = goalReached ? Colors.green : cs.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor:
                        cs.onPrimaryContainer.withValues(alpha: 0.1),
                    color: progressColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk_rounded,
                        size: 24, color: progressColor),
                    const SizedBox(height: 2),
                    Text(
                      '${health.liveSteps}',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'of ${health.stepGoal}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            health.todayStatusText,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: goalReached ? Colors.green.shade700 : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% of daily goal',
            style: tt.bodySmall?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.6),
            ),
          ),
          if (health.pedestrianStatus != 'unknown') ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  health.pedestrianStatus == 'walking'
                      ? Icons.directions_walk
                      : Icons.accessibility_new,
                  size: 14,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  health.pedestrianStatus == 'walking'
                      ? 'Walking'
                      : 'Stopped',
                  style: tt.bodySmall?.copyWith(
                    fontSize: 11,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY STEPS CHART
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyStepsChart extends StatelessWidget {
  final List<MapEntry<DateTime, int>> data;
  final int goal;
  final ColorScheme cs;
  final bool isDark;

  const _WeeklyStepsChart({
    required this.data,
    required this.goal,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxSteps =
        data.fold(goal, (m, e) => e.value > m ? e.value : m).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final ratio = maxSteps > 0
                    ? (entry.value / maxSteps).clamp(0.0, 1.0)
                    : 0.0;
                final reachedGoal = entry.value >= goal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value > 999
                              ? '${(entry.value / 1000).toStringAsFixed(1)}k'
                              : '${entry.value}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio == 0 ? 0.02 : ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: reachedGoal
                                    ? Colors.green
                                    : cs.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: data.map((entry) {
              return Expanded(
                child: Center(
                  child: Text(
                    DateFormat('E').format(entry.key).substring(0, 2),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY STATS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyStatsRow extends StatelessWidget {
  final HealthProvider health;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isDark;

  const _WeeklyStatsRow({
    required this.health,
    required this.cs,
    required this.tt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final best = health.weekBestDay;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.straighten_rounded,
            label: 'Total',
            value: '${health.weekTotalSteps}',
            color: cs.primary,
            isDark: isDark,
            cs: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.trending_up_rounded,
            label: 'Avg/Day',
            value: '${health.weekAverageSteps.toInt()}',
            color: Colors.teal,
            isDark: isDark,
            cs: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.emoji_events_rounded,
            label: 'Best Day',
            value: best != null ? '${best.steps}' : '-',
            color: Colors.amber.shade700,
            isDark: isDark,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEIGHT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _WeightCard extends StatelessWidget {
  final HealthProvider health;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isDark;

  const _WeightCard({
    required this.health,
    required this.cs,
    required this.tt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final latest = health.latestWeight;
    final target = health.targetWeight;
    final entries = health.weightEntries;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current and target
          Row(
            children: [
              Expanded(
                child: _WeightMetric(
                  label: 'Current',
                  value: latest != null
                      ? '${latest.weight.toStringAsFixed(1)} kg'
                      : '- kg',
                  icon: Icons.monitor_weight_outlined,
                  color: cs.primary,
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: cs.outlineVariant.withValues(alpha: 0.3)),
              Expanded(
                child: _WeightMetric(
                  label: 'Target',
                  value: target > 0 ? '${target.toStringAsFixed(1)} kg' : 'Not set',
                  icon: Icons.flag_rounded,
                  color: Colors.green,
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: cs.outlineVariant.withValues(alpha: 0.3)),
              Expanded(
                child: _WeightMetric(
                  label: 'Remaining',
                  value: target > 0 && latest != null
                      ? '${health.weightRemaining.toStringAsFixed(1)} kg'
                      : '- kg',
                  icon: Icons.hourglass_bottom_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          // Progress bar
          if (target > 0 && entries.length >= 2) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: health.weightProgress,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(health.weightProgress * 100).toInt()}% to goal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],

          // Mini weight history
          if (entries.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Recent Entries',
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            ...entries.take(5).map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${e.weight.toStringAsFixed(1)} kg',
                      style: tt.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(e.date),
                      style: tt.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => health.deleteWeightEntry(e.id),
                      child: Icon(Icons.close,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _WeightMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WeightMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// INSIGHT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  final bool isDark;

  const _InsightCard({
    required this.text,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, height: 1.4)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEALTH SETTINGS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HealthSettingsCard extends StatelessWidget {
  final HealthProvider health;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isDark;

  const _HealthSettingsCard({
    required this.health,
    required this.cs,
    required this.tt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Step goal
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.flag_rounded, color: cs.primary, size: 20),
            title: const Text('Daily Step Goal',
                style: TextStyle(fontSize: 13)),
            trailing: Text('${health.stepGoal}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.primary)),
            onTap: () => _showEditGoalDialog(context, health),
          ),
          const Divider(height: 8),
          // Target weight
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading:
                Icon(Icons.monitor_weight, color: Colors.green, size: 20),
            title: const Text('Target Weight',
                style: TextStyle(fontSize: 13)),
            trailing: Text(
                health.targetWeight > 0
                    ? '${health.targetWeight.toStringAsFixed(1)} kg'
                    : 'Not set',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            onTap: () => _showEditTargetWeightDialog(context, health),
          ),
          const Divider(height: 8),
          // Tracking toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            secondary: Icon(Icons.sensors_rounded,
                color: health.trackingEnabled ? cs.primary : Colors.grey,
                size: 20),
            title: const Text('Step Tracking',
                style: TextStyle(fontSize: 13)),
            value: health.trackingEnabled,
            onChanged: (v) => health.setTrackingEnabled(v),
          ),
          const Divider(height: 8),
          // Reset
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading:
                const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            title: const Text('Reset All Health Data',
                style: TextStyle(fontSize: 13, color: Colors.red)),
            onTap: () => _confirmReset(context, health),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, HealthProvider health) {
    final controller =
        TextEditingController(text: health.stepGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Step Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'Steps', hintText: '8000'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              if (val > 0) {
                health.setStepGoal(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditTargetWeightDialog(
      BuildContext context, HealthProvider health) {
    final controller = TextEditingController(
      text: health.targetWeight > 0
          ? health.targetWeight.toStringAsFixed(1)
          : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Target Weight'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Weight (kg)', hintText: '65.0'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                health.setTargetWeight(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, HealthProvider health) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Health Data?'),
        content: const Text(
            'This will permanently delete all step and weight history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              health.resetAllHealthData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Health data reset')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMON WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final ColorScheme cs;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
