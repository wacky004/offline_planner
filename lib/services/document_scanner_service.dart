import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// DocumentScannerService handles camera capture, gallery import,
/// optional crop, and local file persistence for scanned documents.
class DocumentScannerService {
  final ImagePicker _picker = ImagePicker();

  /// Scans a document from [fromCamera] (camera) or gallery.
  /// Returns the saved local file path, or null on cancellation/error.
  Future<String?> scanDocument({required bool fromCamera}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (image == null) return null;

      // Attempt crop/adjust
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust Document',
              toolbarColor: Colors.blueGrey[800]!,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Adjust Document',
              doneButtonTitle: 'Save',
              cancelButtonTitle: 'Cancel',
            ),
          ],
        );
      } catch (e) {
        debugPrint('[DocumentScannerService] Crop skipped: $e');
      }

      final finalPath = croppedFile?.path ?? image.path;
      return await _saveLocally(finalPath);
    } catch (e) {
      debugPrint('[DocumentScannerService] Scan error: $e');
      return null;
    }
  }

  /// Copies the file at [sourcePath] into the app's documents/scanned_docs/ folder.
  Future<String?> _saveLocally(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory(p.join(appDir.path, 'scanned_docs'));
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final destPath = p.join(docsDir.path, 'doc_$timestamp$ext');

      final savedFile = await File(sourcePath).copy(destPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('[DocumentScannerService] Save error: $e');
      return null;
    }
  }

  /// Safely deletes a document file from local storage.
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[DocumentScannerService] Delete error: $e');
    }
  }

  /// Checks whether the file at [filePath] actually exists.
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (_) {
      return false;
    }
  }
}
