import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/backup_service.dart';
import '../services/pin_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinEnabled = false;
  final _pinService = PinService();

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final enabled = await _pinService.isPinLockEnabled();
    if (mounted) setState(() => _pinEnabled = enabled);
  }

  // ─── Sync Helpers ──────────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    final authService = context.read<AuthService>();
    // signInWithGoogle opens the OAuth browser flow and returns true if launched.
    final started = await authService.signInWithGoogle();
    if (!mounted) return;
    if (started) {
      await context.read<SettingsProvider>().setUserMode(UserMode.sync);
      context.read<SyncService>().syncAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in started! Sync will begin once you return.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in failed to start. Please try again.')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await _showConfirmDialog(
      'Sign Out',
      'Your local data will remain on this device. Cloud sync will stop until you sign in again.',
    );
    if (!confirmed || !mounted) return;
    await context.read<AuthService>().signOut();
    await context.read<SettingsProvider>().setUserMode(UserMode.guest);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out. App is now in Guest Mode.')),
      );
    }
  }

  Future<void> _handleSyncNow() async {
    final syncService = context.read<SyncService>();
    await syncService.syncAll();
    if (mounted) {
      await context.read<SettingsProvider>().recordSyncTime();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync complete!')),
      );
    }
  }

  // ─── Backup Helpers ────────────────────────────────────────────────────────

  Future<void> _handleExport(BackupService backupService) async {
    final path = await backupService.exportBackup();
    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Backup saved to:\n$path'), duration: const Duration(seconds: 4)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Export failed. Please try again.')),
      );
    }
  }

  Future<void> _handleImport(BackupService backupService) async {
    final confirmed = await _showConfirmDialog(
      'Import Backup',
      'New data from the backup file will be merged into your existing local data. This will NOT delete your current data.',
    );
    if (!confirmed || !mounted) return;
    final success = await backupService.importBackup();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '✅ Backup imported successfully!' : '❌ Import failed. Check the file format.')),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final authService = context.watch<AuthService>();
    final syncService = context.watch<SyncService>();
    final backupService = context.read<BackupService>();

    final isSignedIn = authService.isSignedIn;
    final isSyncMode = settings.userMode == UserMode.sync;
    final user = authService.currentUser;
    final lastSync = settings.lastSyncTime;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ───────────────────────────────────────────────────
          _sectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(),
          ),

          // ── Calendar & Layout ────────────────────────────────────────────
          _sectionHeader('Calendar & Layout'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency Symbol'),
            trailing: DropdownButton<String>(
              value: settings.currencySymbol,
              underline: const SizedBox(),
              items: ['\$', '€', '£', '¥', '₱']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) settings.setCurrency(val);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_month),
            title: const Text('Default Calendar View'),
            trailing: DropdownButton<CalendarFormat>(
              value: settings.calendarFormat,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: CalendarFormat.month, child: Text('Month')),
                DropdownMenuItem(value: CalendarFormat.twoWeeks, child: Text('Two Weeks')),
                DropdownMenuItem(value: CalendarFormat.week, child: Text('Week')),
              ],
              onChanged: (val) {
                if (val != null) settings.setCalendarFormat(val);
              },
            ),
          ),

          // ── Security ─────────────────────────────────────────────────────
          _sectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Enable PIN Lock'),
            value: _pinEnabled,
            onChanged: (val) async {
              if (val) {
                final hasSetup = await _pinService.hasPinSetup();
                if (!mounted) return;
                if (!hasSetup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PinScreen(isSettingUp: true)),
                  ).then((_) => _loadPinStatus());
                } else {
                  await _pinService.togglePinLock(true);
                  _loadPinStatus();
                }
              } else {
                await _pinService.togglePinLock(false);
                _loadPinStatus();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PinScreen(isSettingUp: true)),
              ).then((_) => _loadPinStatus());
            },
          ),

          // ── Account & Sync ────────────────────────────────────────────────
          _sectionHeader('Account & Sync'),

          // Mode badge
          ListTile(
            leading: Icon(
              isSyncMode ? Icons.cloud_done : Icons.phonelink_off,
              color: isSyncMode ? Colors.green : Colors.grey,
            ),
            title: Text(isSyncMode ? 'Sync Mode' : 'Guest Mode (Offline Only)'),
            subtitle: Text(
              isSyncMode
                  ? (user?.email ?? 'Signed in')
                  : 'No account • All data stays on this device',
            ),
          ),

          // Last sync time
          if (isSyncMode && lastSync != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Last synced: ${DateFormat('MMM d, yyyy – h:mm a').format(lastSync)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ),

          const SizedBox(height: 4),

          // Sync Now
          if (isSyncMode)
            ListTile(
              leading: syncService.isSyncing
                  ? const SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              title: const Text('Sync Now'),
              subtitle: const Text('Push local changes to cloud and pull updates'),
              onTap: syncService.isSyncing ? null : _handleSyncNow,
            ),

          // Sign in / Sign out
          if (!isSignedIn)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign in with Google to Enable Sync'),
              subtitle: const Text('Opens Google sign-in via Supabase — syncs calendar, goals, cookbook & Bible'),
              onTap: _handleSignIn,
            )
          else
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text('App will continue in Guest Mode with local data'),
              onTap: _handleSignOut,
            ),

          // ── Backup & Restore ──────────────────────────────────────────────
          _sectionHeader('Backup & Restore'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Local Backup'),
            subtitle: const Text('Save all data to a JSON file on your device'),
            onTap: () => _handleExport(backupService),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text('Import from Backup'),
            subtitle: const Text('Merge data from a JSON backup file'),
            onTap: () => _handleImport(backupService),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
