import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> scanReceipt({required bool fromCamera}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Receipt',
              toolbarColor: Colors.blueGrey,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Receipt',
            ),
          ],
        );
      } catch (e) {
        debugPrint('Crop error: $e');
      }

      final finalPath = croppedFile?.path ?? image.path;

      // Save locally
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(finalPath).isEmpty ? '.jpg' : p.extension(finalPath);
      final newPath = p.join(receiptsDir.path, 'receipt_$timestamp$ext');

      final savedFile = await File(finalPath).copy(newPath);
      return savedFile.path;
      
    } catch (e) {
      debugPrint('Error scanning receipt: $e');
      return null;
    }
  }
}
