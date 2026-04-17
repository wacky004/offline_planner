import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

/// DocumentScannerService
///
/// Handles camera capture and gallery import for the Document Scanner module.
/// Saves every captured image into the app's private scanned_docs/ directory.
///
/// NOTE: image_cropper has been intentionally removed. It requires a separate
/// UCropActivity + FileProvider registration that conflicts with the one
/// image_picker already registers internally, causing the app to crash after
/// the user confirms the crop. image_picker's built-in quality / resolution
/// options are sufficient for an offline-first document store.
class DocumentScannerService {
  final ImagePicker _picker = ImagePicker();

  // ─── Permission helpers ──────────────────────────────────────────────────────

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    debugPrint('[DocScanner] Camera permission: $status');
    return status.isGranted;
  }

  Future<bool> _requestGalleryPermission() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkInt();
      status = sdkInt >= 33
          ? await Permission.photos.request()
          : await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }
    debugPrint('[DocScanner] Gallery permission: $status');
    return status.isGranted || status.isLimited;
  }

  /// Parses the Android SDK integer from [Platform.operatingSystemVersion],
  /// e.g. "Android 13 (API 33)" → 33. Returns 0 on non-Android or parse failure.
  Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    try {
      final match =
          RegExp(r'API\s+(\d+)').firstMatch(Platform.operatingSystemVersion);
      return int.tryParse(match?.group(1) ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Main entry ──────────────────────────────────────────────────────────────

  /// Captures or imports a document image.
  ///
  /// Returns the absolute path of the saved file inside the app's private
  /// scanned_docs/ directory, or [null] if the user cancelled / permission
  /// was denied / an error occurred.
  Future<String?> scanDocument({required bool fromCamera}) async {
    try {
      // 1 — Request permission before touching image_picker
      final granted = fromCamera
          ? await _requestCameraPermission()
          : await _requestGalleryPermission();

      if (!granted) {
        debugPrint('[DocScanner] Permission not granted — aborting.');
        return null;
      }

      // 2 — Pick image (no crop step — avoids FileProvider conflict crash)
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,        // keep file size reasonable
        maxWidth: 2048,          // cap resolution for storage efficiency
        maxHeight: 2048,
      );

      if (picked == null) {
        debugPrint('[DocScanner] User cancelled picker.');
        return null;
      }

      // 3 — Copy into our private directory so the path never changes
      return await _saveToPrivateDir(picked.path);
    } catch (e, st) {
      debugPrint('[DocScanner] scanDocument error: $e\n$st');
      return null;
    }
  }

  // ─── Private storage ─────────────────────────────────────────────────────────

  /// Copies [sourcePath] into <appDocDir>/scanned_docs/ with a timestamped name.
  Future<String?> _saveToPrivateDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'scanned_docs'));

      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      final ext =
          p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(destDir.path, fileName);

      await File(sourcePath).copy(destPath);
      debugPrint('[DocScanner] Saved → $destPath');
      return destPath;
    } catch (e) {
      debugPrint('[DocScanner] _saveToPrivateDir error: $e');
      return null;
    }
  }

  // ─── Utilities ───────────────────────────────────────────────────────────────

  /// Deletes a document file from storage. Safe to call even if file is missing.
  Future<void> deleteFile(String filePath) async {
    try {
      final f = File(filePath);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('[DocScanner] deleteFile error: $e');
    }
  }

  /// Returns [true] if the file at [filePath] exists on disk.
  Future<bool> fileExists(String filePath) async {
    try {
      return File(filePath).existsSync();
    } catch (_) {
      return false;
    }
  }
}
