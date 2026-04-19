import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../providers/cookbook_provider.dart';
import '../providers/music_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/attendance_provider.dart';
import '../models/entry_type.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(),
      body: Consumer3<PlannerProvider, CookbookProvider, MusicProvider>(
        builder: (context, planner, cookbook, music, _) {
          final settings = context.watch<SettingsProvider>();
          final sym = settings.currencySymbol;

          // ── Monthly stats ──────────────────────────────────────────
          final monthEntries = planner.entries
              .where((e) => e.date.month == now.month && e.date.year == now.year)
              .toList();

          final monthExpenses =
              monthEntries.where((e) => e.type == EntryType.expense).toList();
          final totalExpenses =
              monthExpenses.fold(0.0, (s, e) => s + (e.amount ?? 0));
          final paidExpenses =
              monthExpenses.where((e) => e.isCompletedOrPaid).length;
          final unpaidExpenses = monthExpenses.length - paidExpenses;
          final unpaidTotal = monthExpenses
              .where((e) => !e.isCompletedOrPaid)
              .fold(0.0, (s, e) => s + (e.amount ?? 0));

          final monthTodos =
              monthEntries.where((e) => e.type == EntryType.todo).toList();
          final completedTodos =
              monthTodos.where((e) => e.isCompletedOrPaid).length;
          final pendingTodos = monthTodos.length - completedTodos;

          final monthNotes =
              monthEntries.where((e) => e.type == EntryType.note).length;

          // ── Today stats ────────────────────────────────────────────
          final todayEntries = planner.entries
              .where((e) =>
                  e.date.year == now.year &&
                  e.date.month == now.month &&
                  e.date.day == now.day)
              .toList();
          final todayTodos =
              todayEntries.where((e) => e.type == EntryType.todo).toList();
          final todayTodosCompleted =
              todayTodos.where((e) => e.isCompletedOrPaid).length;
          final todayTodosPending = todayTodos.length - todayTodosCompleted;
          final todayExpenses =
              todayEntries.where((e) => e.type == EntryType.expense).toList();
          final todayExpenseTotal =
              todayExpenses.fold(0.0, (s, e) => s + (e.amount ?? 0));
          final todayNotes =
              todayEntries.where((e) => e.type == EntryType.note).length;

          // ── Upcoming unpaid expenses (next 7 days) ─────────────────
          final next7 = now.add(const Duration(days: 7));
          final upcomingExpenses = planner.entries
              .where((e) =>
                  e.type == EntryType.expense &&
                  !e.isCompletedOrPaid &&
                  e.date.isAfter(now.subtract(const Duration(days: 1))) &&
                  e.date.isBefore(next7))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          // ── Recent notes ───────────────────────────────────────────
          final recentNotes = planner.entries
              .where((e) => e.type == EntryType.note)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // ── Goal stats ─────────────────────────────────────────────
          final goals = planner.goals;
          final activeGoals =
              goals.where((g) => !g.isCompleted).toList()
                ..sort((a, b) {
                  // Sort by proximity to completion (highest progress first)
                  final pa = a.targetAmount > 0
                      ? a.currentAmount / a.targetAmount
                      : 0.0;
                  final pb = b.targetAmount > 0
                      ? b.currentAmount / b.targetAmount
                      : 0.0;
                  return pb.compareTo(pa);
                });
          final completedGoalCount =
              goals.where((g) => g.isCompleted).length;
          final totalSaved =
              goals.fold(0.0, (s, g) => s + g.currentAmount);
          final totalTarget =
              goals.fold(0.0, (s, g) => s + g.targetAmount);
          final totalRemaining =
              (totalTarget - totalSaved).clamp(0.0, double.infinity);
          final overallProgress =
              totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

          // ── Recipe stats ───────────────────────────────────────────
          final allRecipes = cookbook.recipes;
          final monthRecipes = allRecipes
              .where((r) =>
                  r.createdAt.month == now.month &&
                  r.createdAt.year == now.year)
              .length;
          final recentRecipes = List.from(allRecipes)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final favoriteRecipes =
              allRecipes.where((r) => r.isFavorite).length;

          // ── Top category ───────────────────────────────────────────
          String? topCategory;
          if (allRecipes.isNotEmpty) {
            final catCount = <String, int>{};
            for (var r in allRecipes) {
              final cat = r.category.name;
              catCount[cat] = (catCount[cat] ?? 0) + 1;
            }
            topCategory = catCount.entries
                .reduce((a, b) => a.value >= b.value ? a : b)
                .key;
          }

          // ── Music stats ────────────────────────────────────────────
          final allSongs = music.songs;
          final totalPlays =
              allSongs.fold(0, (s, song) => s + song.playCount);
          final topSongs = music.topSongs.take(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ────── GREETING HEADER ──────────────────────────────────
              _TodayHeader(now: now),
              const SizedBox(height: 20),

              // ────── TODAY OVERVIEW ──────────────────────────────────
              _SectionTitle(title: 'Today Overview', icon: Icons.today_rounded),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GlanceCard(
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      title: '$todayTodosPending',
                      subtitle: 'Pending',
                      detail: '$todayTodosCompleted done',
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlanceCard(
                      icon: Icons.receipt_long_rounded,
                      color: Colors.red.shade400,
                      title: '$sym${todayExpenseTotal.toStringAsFixed(0)}',
                      subtitle: 'Expenses',
                      detail: '${todayExpenses.length} items',
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GlanceCard(
                      icon: Icons.edit_note_rounded,
                      color: Colors.blue,
                      title: '$todayNotes',
                      subtitle: 'Notes',
                      detail: '${todayEntries.length} total',
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ────── MONTHLY ANALYTICS ─────────────────────────────
              _SectionTitle(
                title: DateFormat('MMMM yyyy').format(now),
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(height: 10),
              _DashboardCard(
                isDark: isDark,
                cs: cs,
                child: Column(
                  children: [
                    // Expenses row
                    _BigStatBanner(
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.red,
                      label: 'Total Expenses',
                      value: '$sym${totalExpenses.toStringAsFixed(2)}',
                      cs: cs,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ChipStat(
                          label: 'Paid',
                          value: '$paidExpenses',
                          color: Colors.green,
                          cs: cs,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _ChipStat(
                          label: 'Unpaid',
                          value: '$unpaidExpenses',
                          color: Colors.orange,
                          cs: cs,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Unpaid: $sym${unpaidTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Tasks row
                    Row(
                      children: [
                        Icon(Icons.task_alt_rounded,
                            size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        _ChipStat(
                          label: 'Done',
                          value: '$completedTodos',
                          color: Colors.green,
                          cs: cs,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _ChipStat(
                          label: 'Pending',
                          value: '$pendingTodos',
                          color: Colors.amber.shade700,
                          cs: cs,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Notes row
                    Row(
                      children: [
                        Icon(Icons.note_alt_outlined,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Notes Written',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$monthNotes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Upcoming expenses ──────────────────────────────────
              if (upcomingExpenses.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DashboardCard(
                  isDark: isDark,
                  cs: cs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Upcoming Unpaid Expenses',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...upcomingExpenses.take(4).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.title,
                                    style: tt.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$sym${(e.amount ?? 0).toStringAsFixed(0)}',
                                  style: tt.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM d').format(e.date),
                                  style: tt.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              // ── Recent notes ───────────────────────────────────────
              if (recentNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DashboardCard(
                  isDark: isDark,
                  cs: cs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sticky_note_2_outlined,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            'Recent Notes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...recentNotes.take(3).map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Icon(Icons.note_rounded,
                                    size: 14,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.3)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: tt.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d').format(n.date),
                                  style: tt.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ────── SAVINGS GOALS ────────────────────────────────────
              _SectionTitle(
                  title: 'Savings Goals', icon: Icons.savings_rounded),
              const SizedBox(height: 10),
              if (goals.isEmpty)
                _DashboardCard(
                  isDark: isDark,
                  cs: cs,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No savings goals yet',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                // Overall summary banner
                _DashboardCard(
                  isDark: isDark,
                  cs: cs,
                  child: Row(
                    children: [
                      // Progress ring
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: overallProgress,
                              strokeWidth: 5,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: overallProgress >= 1.0
                                  ? Colors.green
                                  : cs.primary,
                            ),
                            Text(
                              '${(overallProgress * 100).toInt()}%',
                              style: tt.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved $sym${totalSaved.toStringAsFixed(0)} of $sym${totalTarget.toStringAsFixed(0)}',
                              style: tt.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Remaining: $sym${totalRemaining.toStringAsFixed(0)}',
                              style: tt.bodySmall?.copyWith(
                                color: totalRemaining > 0
                                    ? Colors.orange.shade700
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeGoals.length} active · $completedGoalCount completed',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Individual active goals
                if (activeGoals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...activeGoals.take(4).map((g) {
                    final progress = g.targetAmount > 0
                        ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                        : 0.0;
                    final remaining =
                        (g.targetAmount - g.currentAmount).clamp(0.0, double.infinity);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _DashboardCard(
                        isDark: isDark,
                        cs: cs,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    g.title,
                                    style: tt.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (progress >= 1.0
                                            ? Colors.green
                                            : cs.primary)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: progress >= 1.0
                                          ? Colors.green
                                          : cs.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 7,
                                backgroundColor: cs.surfaceContainerHighest,
                                color: progress >= 1.0
                                    ? Colors.green
                                    : cs.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved: $sym${g.currentAmount.toStringAsFixed(0)}',
                                  style: tt.bodySmall?.copyWith(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Remaining: $sym${remaining.toStringAsFixed(0)}',
                                  style: tt.bodySmall?.copyWith(
                                    color: remaining > 0
                                        ? Colors.orange.shade700
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
              const SizedBox(height: 24),

              // ────── COOKBOOK ─────────────────────────────────────────
              _SectionTitle(
                  title: 'Cookbook', icon: Icons.restaurant_menu_rounded),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Total',
                      value: '${allRecipes.length}',
                      icon: Icons.menu_book_rounded,
                      color: Colors.orange,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'This Month',
                      value: '$monthRecipes',
                      icon: Icons.add_circle_outline,
                      color: Colors.teal,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Favorites',
                      value: '$favoriteRecipes',
                      icon: Icons.favorite_rounded,
                      color: Colors.pink,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                ],
              ),
              if (recentRecipes.isNotEmpty || topCategory != null) ...[
                const SizedBox(height: 8),
                _DashboardCard(
                  isDark: isDark,
                  cs: cs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (topCategory != null) ...[
                        Row(
                          children: [
                            Icon(Icons.category_rounded,
                                size: 14,
                                color: cs.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 6),
                            Text(
                              'Top Category: ',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              topCategory.toUpperCase(),
                              style: tt.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (recentRecipes.isNotEmpty)
                          const Divider(height: 16),
                      ],
                      if (recentRecipes.isNotEmpty) ...[
                        Text(
                          'Recently Updated',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...recentRecipes.take(3).map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.restaurant,
                                      size: 14,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.4)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: tt.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d').format(r.updatedAt),
                                    style: tt.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ────── MUSIC ─────────────────────────────────────────
              _SectionTitle(
                  title: 'Music', icon: Icons.library_music_rounded),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Songs',
                      value: '${allSongs.length}',
                      icon: Icons.music_note_rounded,
                      color: Colors.deepPurple,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Total Plays',
                      value: '$totalPlays',
                      icon: Icons.play_circle_rounded,
                      color: Colors.indigo,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Playlists',
                      value: '${music.playlists.length}',
                      icon: Icons.queue_music_rounded,
                      color: Colors.purple,
                      isDark: isDark,
                      cs: cs,
                    ),
                  ),
                ],
              ),
              if (topSongs.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DashboardCard(
                  isDark: isDark,
                  cs: cs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Played',
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...topSongs.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final song = entry.value;
                        final medals = ['🥇', '🥈', '🥉'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(medals[idx],
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  song.title,
                                  style: tt.bodySmall?.copyWith(
                                    fontWeight: idx == 0
                                        ? FontWeight.w600
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${song.playCount} plays',
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: cs.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              const SizedBox(height: 24),
              // ────── CAMERA & ATTENDANCE ─────────────────────────────────
              _SectionTitle(title: 'Camera & Attendance', icon: Icons.camera_alt_rounded),
              const SizedBox(height: 10),
              Consumer2<CameraProvider, AttendanceProvider>(
                builder: (context, camera, attendance, _) {
                  final totalDocs = camera.documents.length;
                  final todayAttendance = attendance.getRecordsForDate(DateTime.now()).length;
                  return Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Documents',
                          value: '$totalDocs',
                          icon: Icons.camera_alt_rounded,
                          color: Colors.blue,
                          isDark: isDark,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Attendance Today',
                          value: '$todayAttendance',
                          icon: Icons.fact_check_rounded,
                          color: Colors.green,
                          isDark: isDark,
                          cs: cs,
                        ),
                      ),
                    ],
                  );
                },
              ),
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
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style:
                      tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_note_rounded, size: 28, color: cs.primary),
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
  final Widget child;
  final bool isDark;
  final ColorScheme cs;
  const _DashboardCard(
      {required this.child, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}

class _GlanceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;
  final bool isDark;
  final ColorScheme cs;

  const _GlanceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ColorScheme cs;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _BigStatBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final ColorScheme cs;

  const _BigStatBanner({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;
  final bool isDark;

  const _ChipStat({
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
