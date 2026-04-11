import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// _AuthenticatedClient
//
// A thin http.Client wrapper that injects the Google OAuth2 Bearer token
// into every request header.  Required by the googleapis package.
// ─────────────────────────────────────────────────────────────────────────────

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner;

  _AuthenticatedClient(this._headers, this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

// ─────────────────────────────────────────────────────────────────────────────
// DriveService
//
// Responsibilities:
//   • Sign in / sign out of the user's Google account (native picker)
//   • Upload planner_backup.json to Drive's hidden appDataFolder
//   • Download the latest planner_backup.json from appDataFolder
//   • List available backup files (for future multi-device support)
//
// appDataFolder is a special Drive space that is:
//   - Hidden from the user's normal Drive view
//   - Per-app (only this app can read/write it)
//   - Automatically cleaned up when the app is uninstalled
// ─────────────────────────────────────────────────────────────────────────────

class DriveService extends ChangeNotifier {
  static const String _backupFileName = 'planner_backup.json';
  static const String _driveScope = drive.DriveApi.driveAppdataScope;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [_driveScope]);

  GoogleSignInAccount? _account;
  bool _isBusy = false;
  String? _lastError;

  // ── Public state ──────────────────────────────────────────────────────────

  GoogleSignInAccount? get account => _account;
  bool get isSignedIn => _account != null;
  String? get userEmail => _account?.email;
  String? get userName => _account?.displayName;
  bool get isBusy => _isBusy;
  String? get lastError => _lastError;

  DriveService() {
    // Restore previous sign-in silently on startup
    _silentSignIn();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _account = account;
      notifyListeners();
    });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Attempts to restore the previous Google session without showing UI.
  Future<void> _silentSignIn() async {
    try {
      _account = await _googleSignIn.signInSilently();
      notifyListeners();
    } catch (e) {
      debugPrint('[DriveService] Silent sign-in failed: $e');
    }
  }

  /// Shows the Google account picker. Returns true if the user signed in.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _account = account;
      notifyListeners();
      return account != null;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[DriveService] signIn error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current Google account.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _account = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[DriveService] signOut error: $e');
    }
  }

  // ── Drive API helpers ─────────────────────────────────────────────────────

  /// Builds an authenticated Drive API client using the current account's token.
  Future<drive.DriveApi?> _getDriveApi() async {
    if (_account == null) return null;
    try {
      final authHeaders = await _account!.authHeaders;
      final authClient = _AuthenticatedClient(authHeaders, http.Client());
      return drive.DriveApi(authClient);
    } catch (e) {
      debugPrint('[DriveService] _getDriveApi error: $e');
      return null;
    }
  }

  /// Looks up the file ID of an existing backup in appDataFolder.
  /// Returns null if no backup exists yet.
  Future<String?> _findBackupFileId(drive.DriveApi api) async {
    try {
      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );
      final files = fileList.files;
      if (files == null || files.isEmpty) return null;
      return files.first.id;
    } catch (e) {
      debugPrint('[DriveService] _findBackupFileId error: $e');
      return null;
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  /// Uploads (or overwrites) planner_backup.json to Drive's appDataFolder.
  /// Returns true on success.
  Future<bool> uploadBackup(String jsonContent) async {
    _isBusy = true;
    notifyListeners();

    try {
      final api = await _getDriveApi();
      if (api == null) {
        _lastError = 'Not signed in to Google';
        return false;
      }

      final bytes = utf8.encode(jsonContent);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );

      final existingId = await _findBackupFileId(api);

      if (existingId != null) {
        // Update existing file (preserve same file ID)
        await api.files.update(
          drive.File()..name = _backupFileName,
          existingId,
          uploadMedia: media,
        );
        debugPrint('[DriveService] Updated existing backup: $existingId');
      } else {
        // Create new file in appDataFolder
        final fileMetadata = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await api.files.create(
          fileMetadata,
          uploadMedia: media,
        );
        debugPrint('[DriveService] Created new backup in appDataFolder');
      }

      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[DriveService] uploadBackup error: $e');
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────

  /// Downloads planner_backup.json from Drive's appDataFolder.
  /// Returns the JSON string, or null if no backup exists or on error.
  Future<String?> downloadBackup() async {
    _isBusy = true;
    notifyListeners();

    try {
      final api = await _getDriveApi();
      if (api == null) {
        _lastError = 'Not signed in to Google';
        return null;
      }

      final fileId = await _findBackupFileId(api);
      if (fileId == null) {
        debugPrint('[DriveService] No backup file found in Drive');
        _lastError = null; // Not an error — first-time use
        return null;
      }

      final response = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await response.stream.forEach(bytes.addAll);
      final json = utf8.decode(bytes);
      debugPrint('[DriveService] Downloaded backup (${bytes.length} bytes)');
      _lastError = null;
      return json;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[DriveService] downloadBackup error: $e');
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── Metadata ──────────────────────────────────────────────────────────────

  /// Returns the last-modified DateTime of the Drive backup, or null.
  Future<DateTime?> getBackupModifiedTime() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return null;

      final fileList = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, modifiedTime)',
      );
      final files = fileList.files;
      if (files == null || files.isEmpty) return null;
      return files.first.modifiedTime;
    } catch (e) {
      debugPrint('[DriveService] getBackupModifiedTime error: $e');
      return null;
    }
  }
}
