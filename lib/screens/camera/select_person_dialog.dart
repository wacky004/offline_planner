import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/registered_face.dart';

class SelectPersonDialog extends StatefulWidget {
  final String imagePath;
  const SelectPersonDialog({super.key, required this.imagePath});

  @override
  State<SelectPersonDialog> createState() => _SelectPersonDialogState();
}

class _SelectPersonDialogState extends State<SelectPersonDialog> {
  bool _isProcessing = false;

  Future<void> _logAttendance(RegisteredFace person) async {
    setState(() => _isProcessing = true);
    final provider = context.read<AttendanceProvider>();
    
    final result = await provider.logAttendance(
      person: person,
      imagePath: widget.imagePath,
      source: 'camera',
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context);
      
      if (result == 'already_logged') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${person.name} is already logged for today.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance logged for ${person.name}.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final faces = provider.registeredFaces;

    return AlertDialog(
      title: const Text('Who is this?'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select the person to log attendance:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            if (faces.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No registered faces found. Please register someone first.', textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: faces.length,
                  itemBuilder: (context, index) {
                    final face = faces[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: FileImage(File(face.imagePath)),
                      ),
                      title: Text(face.name),
                      onTap: _isProcessing ? null : () => _logAttendance(face),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
