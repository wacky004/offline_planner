import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Legacy ScannerService kept for backward compatibility.
/// image_cropper has been removed to prevent FileProvider conflicts on Android.
class ScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> scanReceipt({required bool fromCamera}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image == null) return null;

      // Save locally
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!receiptsDir.existsSync()) {
        receiptsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(image.path).isEmpty ? '.jpg' : p.extension(image.path);
      final newPath = p.join(receiptsDir.path, 'receipt_$timestamp$ext');

      final savedFile = await File(image.path).copy(newPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('ScannerService error: $e');
      return null;
    }
  }
}
