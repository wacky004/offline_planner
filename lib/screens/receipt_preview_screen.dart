import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final String imagePath;

  const ReceiptPreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Image not found or corrupted.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
