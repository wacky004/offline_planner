import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../providers/planner_provider.dart';
import '../providers/settings_provider.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../widgets/app_drawer.dart';
import '../widgets/entry_list_item.dart';
import '../widgets/add_entry_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PlannerProvider>(context, listen: false);
    _focusedDay = provider.selectedDate;
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Create New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.note, color: Colors.blue),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEntryDialog(initialType: EntryType.note));
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.red),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEntryDialog(initialType: EntryType.expense));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Add Todo'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEntryDialog(initialType: EntryType.todo));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer<PlannerProvider>(
              builder: (context, provider, child) {
                final dayEntries = provider.entries.where((e) => isSameDay(e.date, selectedDate)).toList();
                
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: dayEntries.isEmpty
                          ? const Center(child: Text('No entries for this day.'))
                          : _buildDayItemsList(dayEntries, scrollController: scrollController),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryBar(PlannerProvider provider, SettingsProvider settings) {
    final todayEntries = provider.entries.where((e) => isSameDay(e.date, provider.selectedDate)).toList();
    
    int notesCount = 0;
    int todosCount = 0;
    double expensesTotal = 0.0;

    for (var e in todayEntries) {
      if (e.type == EntryType.note) notesCount++;
      if (e.type == EntryType.todo) todosCount++;
      if (e.type == EntryType.expense) expensesTotal += (e.amount ?? 0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(DateFormat('MMM d').format(provider.selectedDate) + ': ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('💸 ${settings.currencySymbol}${expensesTotal.toStringAsFixed(0)} | '),
          Text('✅ $todosCount | '),
          Text('📝 $notesCount'),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, DateTime day, DateTime focusedMonth, PlannerProvider provider, {bool isSelected = false, bool isToday = false}) {
    final entries = provider.entries.where((e) => isSameDay(e.date, day)).toList();
    
    int notes = entries.where((e) => e.type == EntryType.note).length;
    int expenses = entries.where((e) => e.type == EntryType.expense).length;
    int todos = entries.where((e) => e.type == EntryType.todo).length;
    
    bool hasUnpaidExpense = entries.any((e) => e.type == EntryType.expense && !e.isCompletedOrPaid);

    bool isCurrentMonth = day.month == focusedMonth.month;

    Color? bgColor;
    if (isSelected) {
      bgColor = Theme.of(context).colorScheme.primaryContainer;
    } else if (isToday) {
      bgColor = Theme.of(context).colorScheme.secondaryContainer;
    } else if (hasUnpaidExpense) {
      bgColor = Colors.red.withOpacity(0.1);
    } else if (isCurrentMonth) {
      bgColor = Theme.of(context).cardColor;
    } else {
      bgColor = Theme.of(context).disabledColor.withOpacity(0.05);
    }

    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : 
                isToday ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 1) : null,
        boxShadow: [
          if (isCurrentMonth && !isSelected && !isToday) 
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                color: isCurrentMonth ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).disabledColor,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Wrap(
              direction: Axis.vertical,
              spacing: 1,
              children: [
                if (notes > 0) _CompactIndicator(icon: '📝', count: notes, color: Colors.blue),
                if (todos > 0) _CompactIndicator(icon: '✅', count: todos, color: Colors.green),
                if (expenses > 0) _CompactIndicator(icon: '💸', count: expenses, color: Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBaseTableCalendar(PlannerProvider provider, SettingsProvider settings, {required bool useCards}) {
    return TableCalendar<Entry>(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: settings.calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      onFormatChanged: (format) {
        settings.setCalendarFormat(format);
      },
      rowHeight: useCards ? 85 : 55,
      daysOfWeekHeight: 24,
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false, // Ensures right side default button is removed and fixed!
      ),
      selectedDayPredicate: (day) => isSameDay(provider.selectedDate, day),
      onDaySelected: (selectedDay, focusedMonth) {
        provider.setSelectedDate(selectedDay);
        setState(() {
          _focusedDay = focusedMonth;
        });
        if (settings.plannerLayoutMode == PlannerLayoutMode.mainGrid) {
          _showDayDetails(context, selectedDay);
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: (day) {
        return provider.entries.where((e) => isSameDay(e.date, day)).toList();
      },
      calendarBuilders: useCards 
        ? CalendarBuilders(
            defaultBuilder: (context, day, focusedMonth) => _buildDayCard(context, day, focusedMonth, provider),
            selectedBuilder: (context, day, focusedMonth) => _buildDayCard(context, day, focusedMonth, provider, isSelected: true),
            todayBuilder: (context, day, focusedMonth) => _buildDayCard(context, day, focusedMonth, provider, isToday: true),
            outsideBuilder: (context, day, focusedMonth) => _buildDayCard(context, day, focusedMonth, provider),
            markerBuilder: (context, date, events) => const SizedBox(),
          )
        : CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox();
              bool hasUnpaidExpense = events.any((e) => e.type == EntryType.expense && !e.isCompletedOrPaid);
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: hasUnpaidExpense ? Colors.red : Colors.blue
                  ),
                ),
              );
            }
          ),
    );
  }

  // Common inner list builder for elements
  Widget _buildDayItemsList(List<Entry> dayEntries, {ScrollController? scrollController}) {
    final notes = dayEntries.where((e) => e.type == EntryType.note).toList();
    final expenses = dayEntries.where((e) => e.type == EntryType.expense).toList();
    final todos = dayEntries.where((e) => e.type == EntryType.todo).toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (notes.isNotEmpty) ...[
          const _SectionHeader(title: 'Notes', icon: Icons.note, color: Colors.blue),
          ...notes.map((e) => EntryListItem(entry: e)),
          const SizedBox(height: 16),
        ],
        if (expenses.isNotEmpty) ...[
          const _SectionHeader(title: 'Expenses', icon: Icons.attach_money, color: Colors.red),
          ...expenses.map((e) => EntryListItem(entry: e)),
          const SizedBox(height: 16),
        ],
        if (todos.isNotEmpty) ...[
          const _SectionHeader(title: 'Todos', icon: Icons.check_circle, color: Colors.green),
          ...todos.map((e) => EntryListItem(entry: e)),
        ],
      ],
    );
  }

  Widget _buildMainGrid(PlannerProvider provider, SettingsProvider settings) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
             child: _buildBaseTableCalendar(provider, settings, useCards: true)
          )
        ),
        _buildSummaryBar(provider, settings),
      ],
    );
  }

  Widget _buildBottomExpand(PlannerProvider provider, SettingsProvider settings) {
    final dayEntries = provider.entries.where((e) => isSameDay(e.date, provider.selectedDate)).toList();

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildBaseTableCalendar(provider, settings, useCards: true),
              ),
            ),
          ],
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.15,
          minChildSize: 0.15,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 4, width: 40,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
                  ),
                  Text(DateFormat('EEEE, MMM d').format(provider.selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  Expanded(
                    child: dayEntries.isEmpty 
                      ? const Center(child: Text('No entries for this day.')) 
                      : _buildDayItemsList(dayEntries, scrollController: scrollController),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOriginal(PlannerProvider provider, SettingsProvider settings) {
    final dayEntries = provider.entries.where((e) => isSameDay(e.date, provider.selectedDate)).toList();

    return Column(
      children: [
        _buildBaseTableCalendar(provider, settings, useCards: false),
        const Divider(),
        Expanded(
          child: dayEntries.isEmpty
              ? const Center(child: Text('Select a date to view entries.'))
              : _buildDayItemsList(dayEntries),
        )
      ],
    );
  }

  Widget _buildTimeBlockLayout(PlannerProvider provider, SettingsProvider settings) {
    final dayEntries = provider.entries.where((e) => isSameDay(e.date, provider.selectedDate)).toList();

    return Column(
      children: [
        _buildBaseTableCalendar(provider, settings, useCards: false),
        const Divider(height: 1),
        Expanded(
          child: _TimeBlockTimeline(provider: provider, dayEntries: dayEntries),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlannerProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        Widget bodyContent;
        switch (settings.plannerLayoutMode) {
          case PlannerLayoutMode.timeBlock:
            bodyContent = _buildTimeBlockLayout(provider, settings);
            break;
          case PlannerLayoutMode.original:
            bodyContent = _buildOriginal(provider, settings);
            break;
          case PlannerLayoutMode.bottomExpand:
            bodyContent = _buildBottomExpand(provider, settings);
            break;
          case PlannerLayoutMode.mainGrid:
          default:
            bodyContent = _buildMainGrid(provider, settings);
            break;
        }

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('Offline Planner'),
            actions: [
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Go to Today',
                onPressed: () {
                  final today = DateTime.now();
                  setState(() => _focusedDay = today);
                  provider.setSelectedDate(today);
                },
              ),
              PopupMenuButton<PlannerLayoutMode>(
                icon: const Icon(Icons.dashboard_customize),
                tooltip: 'Layout Mode',
                onSelected: (mode) {
                  settings.setPlannerLayoutMode(mode);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: PlannerLayoutMode.mainGrid,
                    child: Text('Main Planner Grid'),
                  ),
                  const PopupMenuItem(
                    value: PlannerLayoutMode.bottomExpand,
                    child: Text('Bottom Expand Panel'),
                  ),
                  const PopupMenuItem(
                    value: PlannerLayoutMode.original,
                    child: Text('Original Mode'),
                  ),
                  const PopupMenuItem(
                    value: PlannerLayoutMode.timeBlock,
                    child: Text('Time Block Layout'),
                  ),
                ],
              ),
            ],
          ),
          body: bodyContent,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMenu(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _CompactIndicator extends StatelessWidget {
  final String icon;
  final int count;
  final Color color;

  const _CompactIndicator({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const Expanded(child: Divider(indent: 8)),
        ],
      ),
    );
  }
}

class _TimeBlockTimeline extends StatefulWidget {
  final PlannerProvider provider;
  final List<Entry> dayEntries;
  
  const _TimeBlockTimeline({required this.provider, required this.dayEntries});

  @override
  State<_TimeBlockTimeline> createState() => _TimeBlockTimelineState();
}

class _TimeBlockTimelineState extends State<_TimeBlockTimeline> {
  late ScrollController _scrollController;
  final double _slotHeight = 55.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int currentSlotIndex = (now.hour * 2) + (now.minute >= 30 ? 1 : 0);
    double offset = currentSlotIndex * _slotHeight;
    // Don't scroll past the bottom bounds
    double maxOffset = (48 * _slotHeight) - 400; // rough visible height fallback
    if (maxOffset < 0) maxOffset = 0;
    if (offset > maxOffset) offset = maxOffset;
    
    _scrollController = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addSlotEntry(BuildContext context, int hour, int minute) {
    final sDate = widget.provider.selectedDate;
    final slotDate = DateTime(sDate.year, sDate.month, sDate.day, hour, minute);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Add at ${DateFormat('h:mm a').format(slotDate)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.note, color: Colors.blue),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => AddEntryDialog(initialType: EntryType.note, initialDate: slotDate));
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.red),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => AddEntryDialog(initialType: EntryType.expense, initialDate: slotDate));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Add Todo'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => AddEntryDialog(initialType: EntryType.todo, initialDate: slotDate));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 48,
      itemBuilder: (context, index) {
        final hour = index ~/ 2;
        final minute = (index % 2) * 30;
        final slotTime = DateTime(2000, 1, 1, hour, minute);
        
        final slotEntries = widget.dayEntries.where((e) {
            return e.date.hour == hour && e.date.minute >= minute && e.date.minute < minute + 30;
        }).toList();

        return InkWell(
          onTap: () => _addSlotEntry(context, hour, minute),
          child: Container(
            height: _slotHeight,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 75,
                  child: Center(
                    child: Text(DateFormat('h:mm a').format(slotTime), style: TextStyle(fontSize: 12, color: Theme.of(context).disabledColor)),
                  ),
                ),
                Container(width: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: slotEntries.isEmpty 
                      ? const SizedBox() 
                      : Wrap(
                          spacing: 4, runSpacing: 4,
                          children: slotEntries.map((e) {
                              IconData ic; Color c;
                              if (e.type == EntryType.note) { ic = Icons.note; c = Colors.blue; }
                              else if (e.type == EntryType.expense) { ic = Icons.attach_money; c = Colors.red; }
                              else { ic = Icons.check_circle; c = Colors.green; }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: c.withOpacity(0.3))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(ic, size: 12, color: c),
                                    const SizedBox(width: 4),
                                    Flexible(child: Text(e.title, style: TextStyle(fontSize: 11, color: c), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]
                                )
                              );
                          }).toList(),
                      ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
