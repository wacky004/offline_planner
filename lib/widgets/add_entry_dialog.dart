import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../providers/planner_provider.dart';
import '../providers/music_provider.dart';

class AddEntryDialog extends StatefulWidget {
  final Entry? entryToEdit;
  final EntryType? initialType;
  final DateTime? initialDate;

  const AddEntryDialog({super.key, this.entryToEdit, this.initialType, this.initialDate});

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late EntryType _type;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _amountController;
  bool _isCompletedOrPaid = false;
  bool _hasReminder = false;
  DateTime? _reminderTime;
  String? _alarmSoundId;

  @override
  void initState() {
    super.initState();
    final e = widget.entryToEdit;
    _type = e?.type ?? widget.initialType ?? EntryType.todo;
    _titleController = TextEditingController(text: e?.title ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _amountController = TextEditingController(text: e?.amount?.toString() ?? '');
    _isCompletedOrPaid = e?.isCompletedOrPaid ?? false;
    _hasReminder = e?.hasReminder ?? false;
    _reminderTime = e?.reminderTime;
    _alarmSoundId = e?.alarmSoundId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _reminderTime ?? now;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;
    
    setState(() {
      _reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _showAlarmSoundPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer<MusicProvider>(
          builder: (ctx, music, _) {
            if (music.songs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No songs found in your local Music Library.\nGo to the Music tab to import some MP3s!', textAlign: TextAlign.center),
                ),
              );
            }
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Select Alarm Sound', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_off),
                  title: const Text('Default System Sound'),
                  trailing: _alarmSoundId == null ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _alarmSoundId = null);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: music.songs.length,
                    itemBuilder: (context, index) {
                      final song = music.songs[index];
                      final isSelected = _alarmSoundId == song.id;
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(song.title, maxLines: 1),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: () {
                          // Optional: we can invoke music.play(song) here to preview
                          setState(() => _alarmSoundId = song.id);
                          Navigator.pop(ctx);
                        },
                      );
                    }
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_hasReminder && _reminderTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a reminder date/time')));
        return;
      }
      if (_hasReminder && _reminderTime!.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder time must be in the future')));
        return;
      }

      final provider = Provider.of<PlannerProvider>(context, listen: false);
      final entry = Entry(
        id: widget.entryToEdit?.id ?? const Uuid().v4(),
        type: _type,
        title: _titleController.text,
        notes: _notesController.text,
        amount: _type == EntryType.expense ? double.tryParse(_amountController.text) : null,
        date: widget.entryToEdit?.date ?? widget.initialDate ?? provider.selectedDate,
        isCompletedOrPaid: _isCompletedOrPaid,
        hasReminder: _hasReminder,
        reminderTime: _reminderTime,
        alarmSoundId: _alarmSoundId,
      );

      if (widget.entryToEdit != null) {
        provider.updateEntry(entry);
      } else {
        provider.addEntry(entry);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entryToEdit == null ? 'Add Entry' : 'Edit Entry'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<EntryType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: EntryType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              if (_type == EntryType.expense)
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              if (_type != EntryType.note)
                SwitchListTile(
                  title: Text(_type == EntryType.expense ? 'Paid' : 'Completed'),
                  value: _isCompletedOrPaid,
                  onChanged: (val) => setState(() => _isCompletedOrPaid = val),
                  contentPadding: EdgeInsets.zero,
                ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Enable Reminder'),
                value: _hasReminder,
                onChanged: (val) {
                  setState(() {
                    _hasReminder = val;
                    if (_hasReminder && _reminderTime == null) {
                      _reminderTime = DateTime.now().add(const Duration(minutes: 5));
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasReminder) ...[
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(_reminderTime == null ? 'Set Time' : DateFormat('MMM d, yyyy - h:mm a').format(_reminderTime!)),
                          trailing: const Icon(Icons.edit, size: 16),
                          onTap: _pickDateTime,
                          dense: true,
                        ),
                        ListTile(
                          leading: const Icon(Icons.music_note),
                          title: const Text('Alarm Sound'),
                          subtitle: Text(
                             _alarmSoundId == null ? 'Default System Sound' : 'Custom track selected',
                             style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                          trailing: const Icon(Icons.keyboard_arrow_down, size: 16),
                          onTap: _showAlarmSoundPicker,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
