import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart' show SyncService;
import 'services/backup_service.dart' show BackupService;
import 'services/drive_service.dart' show DriveService;

import 'providers/planner_provider.dart';
import 'providers/cookbook_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/music_provider.dart';
import 'providers/health_provider.dart';
import 'providers/document_scanner_provider.dart';
import 'screens/main_nav.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase initialization ────────────────────────────────────────────────
  // Replace SupabaseConfig values with your real project URL and anon key.
  // See lib/config/supabase_config.dart
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase init skipped (check config): $e');
  }
  // ──────────────────────────────────────────────────────────────────────────

  final dbService = DatabaseService();
  await dbService.init();

  final notifService = NotificationService();
  await notifService.init();

  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlannerProvider(dbService, notifService)),
        ChangeNotifierProvider(create: (_) => CookbookProvider(dbService)),
        ChangeNotifierProvider(create: (_) => BibleProvider(dbService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider(dbService)),
        ChangeNotifierProvider(create: (_) => HealthProvider(dbService)),
        ChangeNotifierProvider(create: (_) => DocumentScannerProvider(dbService)),
        // Auth + Sync (order matters: SyncService depends on AuthService)
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProxyProvider<AuthService, SyncService>(
          create: (ctx) => SyncService(dbService, ctx.read<AuthService>()),
          update: (ctx, auth, prev) => prev ?? SyncService(dbService, auth),
        ),
        // DriveService must come before BackupService (BackupService depends on it)
        ChangeNotifierProvider<DriveService>(create: (_) => DriveService()),
        // BackupService orchestrates local + Drive sync
        ChangeNotifierProxyProvider<DriveService, BackupService>(
          create: (ctx) => BackupService(dbService, ctx.read<DriveService>()),
          update: (ctx, drv, prev) => prev ?? BackupService(dbService, drv),
        ),

      ],
      child: const PlannerApp(),
    ),
  );
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Offline Planner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}

