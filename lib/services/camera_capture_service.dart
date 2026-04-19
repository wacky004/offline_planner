import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

/// DocumentScannerService
///
/// Handles camera capture and gallery import.
/// Saves images into the app's private scanned_docs/ directory.
///
/// Permission strategy:
///   Camera   → Permission.camera
///   Gallery  → Android 14+ (API 34+): Permission.photos (READ_MEDIA_IMAGES)
///              Android 13  (API 33):   Permission.photos
///              Android ≤12 (API ≤32):  Permission.storage
///
/// On Android 14+, the system may grant "partial" access (limited selection).
/// We treat both .granted AND .limited as sufficient to proceed — image_picker
/// will open the system photo picker which respects whatever the user allowed.
///
/// NOTE: image_cropper has been intentionally REMOVED. It conflicts with
/// image_picker's internal FileProvider, crashing the app on Android.
class CameraCaptureService {
  final ImagePicker _picker = ImagePicker();

  // ─── SDK detection ───────────────────────────────────────────────────────────

  static int? _cachedSdk;

  Future<int> _sdkInt() async {
    if (_cachedSdk != null) return _cachedSdk!;
    if (!Platform.isAndroid) return 0;
    try {
      // Platform.operatingSystemVersion format:  "Android 14 (API 34)"
      final m = RegExp(r'API\s+(\d+)')
          .firstMatch(Platform.operatingSystemVersion);
      _cachedSdk = int.tryParse(m?.group(1) ?? '') ?? 0;
    } catch (_) {
      _cachedSdk = 0;
    }
    return _cachedSdk!;
  }

  // ─── Permissions ─────────────────────────────────────────────────────────────

  /// Returns true if camera permission is granted.
  Future<bool> _hasCameraPermission() async {
    // Check first — avoid redundant OS dialog
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    status = await Permission.camera.request();
    debugPrint('[DocScanner] Camera → $status');
    return status.isGranted;
  }

  /// Returns true if gallery/storage permission is granted OR limited.
  /// On Android 13+ (API 33+) the system photo picker is used, which does NOT
  /// require READ_MEDIA_IMAGES — so we skip the permission check entirely and
  /// return true to let image_picker open the system picker directly.
  Future<bool> _hasGalleryPermission() async {
    final sdk = await _sdkInt();

    // Android 13+ (API 33+): the system photo picker is permission-free.
    if (Platform.isAndroid && sdk >= 33) {
      debugPrint('[DocScanner] Android API $sdk: using system photo picker (no permission needed).');
      return true;
    }

    Permission perm;
    if (Platform.isIOS) {
      perm = Permission.photos;
    } else {
      // Android ≤12 uses READ_EXTERNAL_STORAGE
      perm = Permission.storage;
    }

    var status = await perm.status;
    debugPrint('[DocScanner] Gallery pre-check → $status (SDK $sdk)');

    // .limited = partial access — still usable via photo picker
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) return false;

    status = await perm.request();
    debugPrint('[DocScanner] Gallery after request → $status');
    return status.isGranted || status.isLimited;
  }

  // ─── Main entry ──────────────────────────────────────────────────────────────

  /// Picks an image from [fromCamera]=true (camera) or false (gallery).
  /// Returns the absolute path of the saved private copy, or null on failure/cancel.
  Future<String?> scanDocument({required bool fromCamera}) async {
    try {
      // 1 — Permission gate (gallery on Android 13+ skips this)
      final ok = fromCamera
          ? await _hasCameraPermission()
          : await _hasGalleryPermission();

      if (!ok) {
        debugPrint('[DocScanner] Permission not granted.');
        return null;
      }

      // 2 — Pick image
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (picked == null) {
        debugPrint('[DocScanner] User cancelled or no image returned.');
        return null;
      }

      // 3 — Verify the file actually exists before copying
      if (!File(picked.path).existsSync()) {
        debugPrint('[DocScanner] Picked file not found at path: ${picked.path}');
        return null;
      }

      // 4 — Copy into private storage
      return await _copyToPrivateDir(picked.path);
    } catch (e, st) {
      debugPrint('[DocScanner] scanDocument error: $e\n$st');
      return null;
    }
  }

  // ─── Storage ─────────────────────────────────────────────────────────────────

  Future<String?> _copyToPrivateDir(String src) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'scanned_docs'));
      if (!destDir.existsSync()) destDir.createSync(recursive: true);

      final ext = p.extension(src).isEmpty ? '.jpg' : p.extension(src);
      final dest =
          p.join(destDir.path, 'doc_${DateTime.now().millisecondsSinceEpoch}$ext');

      await File(src).copy(dest);
      debugPrint('[DocScanner] Saved → $dest');
      return dest;
    } catch (e) {
      debugPrint('[DocScanner] _copyToPrivateDir error: $e');
      return null;
    }
  }

  // ─── Utilities ───────────────────────────────────────────────────────────────

  Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (e) {
      debugPrint('[DocScanner] deleteFile error: $e');
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
