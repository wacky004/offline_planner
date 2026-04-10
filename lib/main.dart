import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/pin_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/backup_service.dart';
import 'providers/planner_provider.dart';
import 'providers/cookbook_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/music_provider.dart';
import 'screens/pin_screen.dart';
import 'screens/main_nav.dart';
import 'screens/mode_selection_screen.dart';

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
        // Auth + Sync (order matters: SyncService depends on AuthService)
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProxyProvider<AuthService, SyncService>(
          create: (ctx) => SyncService(dbService, ctx.read<AuthService>()),
          update: (ctx, auth, prev) => prev ?? SyncService(dbService, auth),
        ),
        // BackupService as plain Provider (not ChangeNotifier)
        Provider<BackupService>(create: (_) => BackupService(dbService)),
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
          home: const InitialScreenDispatcher(),
        );
      },
    );
  }
}

class InitialScreenDispatcher extends StatefulWidget {
  const InitialScreenDispatcher({super.key});

  @override
  State<InitialScreenDispatcher> createState() => _InitialScreenDispatcherState();
}

class _InitialScreenDispatcherState extends State<InitialScreenDispatcher> {
  bool _isLoading = true;
  bool _requiresPin = false;
  bool _needsModeSelection = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // First-ever launch: no mode chosen yet
    final userMode = prefs.getString('user_mode');
    if (userMode == null) {
      setState(() {
        _needsModeSelection = true;
        _isLoading = false;
      });
      return;
    }

    // Check if PIN is required
    final pinService = PinService();
    final pinEnabled = await pinService.isPinLockEnabled();
    final hasPin = await pinService.hasPinSetup();

    setState(() {
      _requiresPin = pinEnabled && hasPin;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_needsModeSelection) return const ModeSelectionScreen();
    if (_requiresPin) return const PinScreen(isSettingUp: false);
    return const MainNav();
  }
}
