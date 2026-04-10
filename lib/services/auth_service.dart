import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth in a [ChangeNotifier] so widgets can react to
/// sign-in / sign-out events exactly as they did with Firebase Auth.
class AuthService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  AuthService() {
    // React to Supabase auth changes
    _client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  /// Currently signed-in user, or null in Guest Mode.
  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  /// The user's unique ID used as the Supabase RLS row key.
  String? get userId => currentUser?.id;

  /// Sign in with Google via Supabase OAuth.
  ///
  /// On mobile this launches the browser; on web it stays in-page.
  /// Returns [true] if the sign-in flow was started successfully.
  Future<bool> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.offlineplanner://login-callback/',
      );
      return true;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
    }
  }
}
