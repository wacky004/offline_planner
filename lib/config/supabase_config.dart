// ─────────────────────────────────────────────────────────────────────────────
// Supabase configuration
//
// Replace the placeholder values below with your real project credentials from:
//   https://supabase.com/dashboard → your project → Settings → API
//
// NEVER commit real secrets to version control.
// Consider loading these from --dart-define or a .env file in production.
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseConfig {
  /// Your Supabase Project URL, e.g. https://xxxx.supabase.co
  static const String projectUrl = 'https://YOUR_PROJECT_REF.supabase.co';

  /// Your Supabase anon (public) key
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
