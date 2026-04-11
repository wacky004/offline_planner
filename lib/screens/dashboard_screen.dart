import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../providers/cookbook_provider.dart';
import '../providers/music_provider.dart';
import '../providers/settings_provider.dart';
import '../models/entry_type.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Scaffold(
      body: Consumer3<PlannerProvider, CookbookProvider, MusicProvider>(
        builder: (context, planner, cookbook, music, _) {
          final settings = context.watch<SettingsProvider>();

          // ── Compute monthly stats ──────────────────────────────────
          final monthEntries = planner.entries
              .where((e) => e.date.month == now.month && e.date.year == now.year)
              .toList();

          final monthExpenses = monthEntries.where((e) => e.type == EntryType.expense);
          final totalExpenses = monthExpenses.fold(0.0, (s, e) => s + (e.amount ?? 0));
          final unpaidExpenses = monthExpenses.where((e) => !e.isCompletedOrPaid);

          final monthTodos = monthEntries.where((e) => e.type == EntryType.todo);
          final completedTodos = monthTodos.where((e) => e.isCompletedOrPaid).length;
          final pendingTodos = monthTodos.length - completedTodos;

          final monthNotes = monthEntries.where((e) => e.type == EntryType.note).length;

          // ── Today stats ────────────────────────────────────────────
          final todayEntries = planner.entries.where((e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day).toList();
          final todayTodos = todayEntries.where((e) => e.type == EntryType.todo);
          final todayExpenses = todayEntries.where((e) => e.type == EntryType.expense);

          // ── Goal stats ─────────────────────────────────────────────
          final goals = planner.goals;
          final activeGoals = goals.where((g) => !g.isCompleted).toList();
          final completedGoals = goals.where((g) => g.isCompleted).length;
          final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
          final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
          final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

          // ── Recipe stats ───────────────────────────────────────────
          final allRecipes = cookbook.recipes;
          final monthRecipes = allRecipes.where((r) =>
              r.createdAt.month == now.month && r.createdAt.year == now.year).length;
          final recentRecipes = List.from(allRecipes)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final favoriteRecipes = allRecipes.where((r) => r.isFavorite).length;

          // ── Music stats ────────────────────────────────────────────
          final allSongs = music.songs;
          final totalPlays = allSongs.fold(0, (s, song) => s + song.playCount);
          final topSongs = music.topSongs.take(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ── Today header ────────────────────────────────────────
              _TodayHeader(now: now),
              const SizedBox(height: 16),

              // ── Today quick glance ─────────────────────────────────
              _SectionTitle(title: 'Today', icon: Icons.today_rounded),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MiniStatCard(
                    label: 'Todos',
                    value: '${todayTodos.length}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStatCard(
                    label: 'Expenses',
                    value: '${todayExpenses.length}',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.red,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStatCard(
                    label: 'Entries',
                    value: '${todayEntries.length}',
                    icon: Icons.edit_note_rounded,
                    color: cs.primary,
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // ── Monthly overview ───────────────────────────────────
              _SectionTitle(
                title: DateFormat('MMMM yyyy').format(now),
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(height: 8),
              _DashboardCard(
                children: [
                  _StatRow(
                    icon: Icons.attach_money,
                    color: Colors.red,
                    label: 'Total Expenses',
                    value: '${settings.currencySymbol}${totalExpenses.toStringAsFixed(2)}',
                  ),
                  _StatRow(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    label: 'Unpaid Expenses',
                    value: '${unpaidExpenses.length}',
                  ),
                  const Divider(height: 20),
                  _StatRow(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: 'Completed Tasks',
                    value: '$completedTodos',
                  ),
                  _StatRow(
                    icon: Icons.pending_actions,
                    color: Colors.amber,
                    label: 'Pending Tasks',
                    value: '$pendingTodos',
                  ),
                  const Divider(height: 20),
                  _StatRow(
                    icon: Icons.note_alt_outlined,
                    color: Colors.blue,
                    label: 'Notes Written',
                    value: '$monthNotes',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Savings Goals ──────────────────────────────────────
              _SectionTitle(title: 'Savings Goals', icon: Icons.savings_rounded),
              const SizedBox(height: 8),
              _DashboardCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${settings.currencySymbol}${totalSaved.toStringAsFixed(0)} / ${settings.currencySymbol}${totalTarget.toStringAsFixed(0)}',
                              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedGoals of ${goals.length} goals completed',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: overallProgress,
                              strokeWidth: 5,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: overallProgress >= 1.0 ? Colors.green : cs.primary,
                            ),
                            Text(
                              '${(overallProgress * 100).toInt()}%',
                              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (activeGoals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...activeGoals.take(3).map((g) {
                      final progress = g.targetAmount > 0
                          ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(g.title,
                                      style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                Text(
                                  '${settings.currencySymbol}${(g.targetAmount - g.currentAmount).toStringAsFixed(0)} left',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                                color: progress >= 1.0 ? Colors.green : cs.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── Cookbook ────────────────────────────────────────────
              _SectionTitle(title: 'Cookbook', icon: Icons.restaurant_menu_rounded),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MiniStatCard(
                    label: 'Total',
                    value: '${allRecipes.length}',
                    icon: Icons.menu_book_rounded,
                    color: Colors.orange,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStatCard(
                    label: 'This Month',
                    value: '$monthRecipes',
                    icon: Icons.add_circle_outline,
                    color: Colors.teal,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStatCard(
                    label: 'Favorites',
                    value: '$favoriteRecipes',
                    icon: Icons.favorite_rounded,
                    color: Colors.pink,
                  )),
                ],
              ),
              if (recentRecipes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DashboardCard(
                  children: [
                    Text('Recently Updated', style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    )),
                    const SizedBox(height: 6),
                    ...recentRecipes.take(3).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.title, style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(DateFormat('MMM d').format(r.updatedAt),
                              style: tt.bodySmall?.copyWith(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                    )),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // ── Music ──────────────────────────────────────────────
              _SectionTitle(title: 'Music', icon: Icons.library_music_rounded),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MiniStatCard(
                    label: 'Songs',
                    value: '${allSongs.length}',
                    icon: Icons.music_note_rounded,
                    color: Colors.deepPurple,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStatCard(
                    label: 'Total Plays',
                    value: '$totalPlays',
                    icon: Icons.play_circle_rounded,
                    color: Colors.indigo,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStatCard(
                    label: 'Playlists',
                    value: '${music.playlists.length}',
                    icon: Icons.queue_music_rounded,
                    color: Colors.purple,
                  )),
                ],
              ),
              if (topSongs.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DashboardCard(
                  children: [
                    Text('Top Played', style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    )),
                    const SizedBox(height: 6),
                    ...topSongs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final song = entry.value;
                      final medals = ['🥇', '🥈', '🥉'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(medals[idx], style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              song.title,
                              style: tt.bodySmall?.copyWith(fontWeight: idx == 0 ? FontWeight.w600 : null),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            )),
                            Text('${song.playCount} plays',
                                style: tt.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _TodayHeader extends StatelessWidget {
  final DateTime now;
  const _TodayHeader({required this.now});

  String _greeting() {
    final hour = now.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(now),
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
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

class _DashboardCard extends StatelessWidget {
  final List<Widget> children;
  const _DashboardCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8))),
          ),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }
}
