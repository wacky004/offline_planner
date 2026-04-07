import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../providers/planner_provider.dart';
import '../providers/settings_provider.dart';
import 'add_entry_dialog.dart';

class EntryListItem extends StatelessWidget {
  final Entry entry;

  const EntryListItem({super.key, required this.entry});

  Future<void> _confirmDelete(BuildContext context, PlannerProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this ${entry.type.name}?'),
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
        await provider.deleteEntry(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted'), duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete entry'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);

    IconData icon;
    Color color;

    switch (entry.type) {
      case EntryType.expense:
        icon = Icons.attach_money;
        color = Colors.red;
        break;
      case EntryType.todo:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case EntryType.note:
        icon = Icons.note;
        color = Colors.blue;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          entry.title,
          style: TextStyle(
            decoration: entry.isCompletedOrPaid 
              ? TextDecoration.lineThrough 
              : TextDecoration.none,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.notes.isNotEmpty) Text(entry.notes),
            if (entry.type == EntryType.expense && entry.amount != null)
              Text('${settings.currencySymbol}${entry.amount!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            if (entry.hasReminder && entry.reminderTime != null && !entry.isCompletedOrPaid)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.alarm, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.reminderTime!.month}/${entry.reminderTime!.day} @ ${entry.reminderTime!.hour}:${entry.reminderTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.type != EntryType.note)
              Checkbox(
                value: entry.isCompletedOrPaid,
                onChanged: (_) {
                  provider.toggleEntryStatus(entry);
                },
              ),
            PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') {
                  showDialog(
                    context: context, 
                    builder: (context) => AddEntryDialog(entryToEdit: entry)
                  );
                } else if (val == 'delete') {
                  _confirmDelete(context, provider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
