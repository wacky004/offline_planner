import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/pin_service.dart';
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

  // ─── Confirmation dialog helper ───────────────────────────────────────────

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue')),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Sync & Backup actions ────────────────────────────────────────────────

  Future<void> _handleSyncAndBackup(SyncBackupService service) async {
    await service.syncAndBackup();
    if (!mounted) return;
    final msg = switch (service.status) {
      SyncStatus.success => '✅ Backup complete! Data saved locally.',
      SyncStatus.failed  =>
        '❌ Backup failed: ${service.lastError ?? 'Unknown error'}',
      _ => '',
    };
    if (msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRestoreFromLocal(SyncBackupService service) async {
    final hasBackup = await service.localBackupExists;
    if (!mounted) return;

    if (!hasBackup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No local backup found. Run "Sync & Backup" first.')),
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Restore from Backup',
      'This will merge your latest local backup into the current database. '
      'Newer records on this device will not be overwritten. Continue?',
    );
    if (!confirmed || !mounted) return;

    final ok = await service.restoreFromLocalBackup();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ Restore complete!' : '❌ Restore failed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleImportFromFile(SyncBackupService service) async {
    final confirmed = await _showConfirmDialog(
      'Import from File',
      'Pick a planner_backup.json file to merge into your local database. '
      'Records with a newer "updatedAt" date will overwrite older ones.',
    );
    if (!confirmed || !mounted) return;

    final ok = await service.importFromFile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ Import successful!' : '❌ Import failed. Check the file.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final backup = context.watch<SyncBackupService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _sectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(),
          ),

          // ── Calendar & Layout ───────────────────────────────────────────
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
                DropdownMenuItem(
                    value: CalendarFormat.month, child: Text('Month')),
                DropdownMenuItem(
                    value: CalendarFormat.twoWeeks, child: Text('Two Weeks')),
                DropdownMenuItem(
                    value: CalendarFormat.week, child: Text('Week')),
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
                    MaterialPageRoute(
                        builder: (_) => const PinScreen(isSettingUp: true)),
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
                MaterialPageRoute(
                    builder: (_) => const PinScreen(isSettingUp: true)),
              ).then((_) => _loadPinStatus());
            },
          ),

          // ── Backup & Sync ─────────────────────────────────────────────────
          _sectionHeader('Backup & Sync'),
          _SyncBackupCard(
            service: backup,
            onSyncAndBackup: () => _handleSyncAndBackup(backup),
            onRestoreFromLocal: () => _handleRestoreFromLocal(backup),
            onImportFromFile: () => _handleImportFromFile(backup),
          ),

          const SizedBox(height: 32),
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

// ─────────────────────────────────────────────────────────────────────────────
// Premium Sync & Backup card widget
// ─────────────────────────────────────────────────────────────────────────────

class _SyncBackupCard extends StatelessWidget {
  final SyncBackupService service;
  final VoidCallback onSyncAndBackup;
  final VoidCallback onRestoreFromLocal;
  final VoidCallback onImportFromFile;

  const _SyncBackupCard({
    required this.service,
    required this.onSyncAndBackup,
    required this.onRestoreFromLocal,
    required this.onImportFromFile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status visuals
    final (statusText, statusIcon, statusColor) = switch (service.status) {
      SyncStatus.idle    => ('Idle', Icons.cloud_upload_outlined, cs.onSurface.withValues(alpha: 0.5)),
      SyncStatus.syncing => ('Syncing…', Icons.sync, cs.primary),
      SyncStatus.success => ('Backup complete', Icons.cloud_done_outlined, Colors.green),
      SyncStatus.failed  => ('Failed', Icons.cloud_off_outlined, Colors.redAccent),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        color: isDark
            ? cs.surfaceContainerHighest
            : cs.primaryContainer.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.backup_rounded, color: cs.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Local Backup', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'All data saved as planner_backup.json',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Status row ─────────────────────────────────────────────
              Row(
                children: [
                  if (service.status == SyncStatus.syncing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  else
                    Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: tt.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                  if (service.lastSync != null) ...[
                    Text(
                      '  ·  Last: ${DateFormat('MMM d, h:mm a').format(service.lastSync!)}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // ── PRIMARY BUTTON: Sync & Backup ──────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: service.isSyncing ? null : onSyncAndBackup,
                  icon: service.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: Text(
                    service.isSyncing ? 'Backing up…' : 'Sync & Backup',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Google Drive toggle ────────────────────────────────────
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                secondary: Icon(Icons.drive_file_rename_outline_rounded,
                    color: service.driveEnabled ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                    size: 20),
                title: Text(
                  'Enable Google Drive Sync',
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  service.driveEnabled
                      ? 'Upload & download on each backup'
                      : 'Off — local backup only',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                value: service.driveEnabled,
                onChanged: (val) => service.setDriveEnabled(val),
              ),

              const Divider(height: 24),

              // ── Secondary actions ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SecondaryActionButton(
                      icon: Icons.restore_rounded,
                      label: 'Restore',
                      onTap: service.isSyncing ? null : onRestoreFromLocal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryActionButton(
                      icon: Icons.file_open_rounded,
                      label: 'Import File',
                      onTap: service.isSyncing ? null : onImportFromFile,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Includes badge ─────────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  'Calendar', 'Expenses', 'Goals', 'Cookbook', 'Bible',
                ].map((label) => _Chip(label)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}
