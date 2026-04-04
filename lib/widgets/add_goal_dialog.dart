import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../providers/planner_provider.dart';

class AddGoalDialog extends StatefulWidget {
  final Goal? goalToEdit;

  const AddGoalDialog({super.key, this.goalToEdit});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  late TextEditingController _currentController;

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetController = TextEditingController(text: g?.targetAmount.toString() ?? '');
    _currentController = TextEditingController(text: g?.currentAmount.toString() ?? '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PlannerProvider>(context, listen: false);
      final goal = Goal(
        id: widget.goalToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text,
        targetAmount: double.tryParse(_targetController.text) ?? 0.0,
        currentAmount: double.tryParse(_currentController.text) ?? 0.0,
      );

      if (widget.goalToEdit != null) {
        provider.updateGoal(goal);
      } else {
        provider.addGoal(goal);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.goalToEdit == null ? 'Create Goal' : 'Edit Goal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'New Car, Vacation, etc.'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Amount'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),
              if (widget.goalToEdit != null)
                TextFormField(
                  controller: _currentController,
                  decoration: const InputDecoration(labelText: 'Current Saved Amount'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (double.tryParse(val) == null) return 'Must be a number';
                    return null;
                  },
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
