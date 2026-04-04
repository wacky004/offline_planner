import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../providers/planner_provider.dart';

class AddEntryDialog extends StatefulWidget {
  final Entry? entryToEdit;

  const AddEntryDialog({super.key, this.entryToEdit});

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

  @override
  void initState() {
    super.initState();
    final e = widget.entryToEdit;
    _type = e?.type ?? EntryType.todo;
    _titleController = TextEditingController(text: e?.title ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _amountController = TextEditingController(text: e?.amount?.toString() ?? '');
    _isCompletedOrPaid = e?.isCompletedOrPaid ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PlannerProvider>(context, listen: false);
      final entry = Entry(
        id: widget.entryToEdit?.id ?? const Uuid().v4(),
        type: _type,
        title: _titleController.text,
        notes: _notesController.text,
        amount: _type == EntryType.expense ? double.tryParse(_amountController.text) : null,
        date: widget.entryToEdit?.date ?? provider.selectedDate,
        isCompletedOrPaid: _isCompletedOrPaid,
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
