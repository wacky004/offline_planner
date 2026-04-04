import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/pin_service.dart';
import 'providers/planner_provider.dart';
import 'providers/cookbook_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/pin_screen.dart';
import 'screens/main_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbService = DatabaseService();
  await dbService.init();
  
  final notifService = NotificationService();
  await notifService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlannerProvider(dbService, notifService)),
        ChangeNotifierProvider(create: (_) => CookbookProvider(dbService)),
        ChangeNotifierProvider(create: (_) => BibleProvider(dbService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    final pinService = PinService();
    
    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
      setState(() {
        _needsSetup = true;
        _isLoading = false;
      });
      return;
    }

    final enabled = await pinService.isPinLockEnabled();
    final hasPin = await pinService.hasPinSetup();
    
    setState(() {
      _requiresPin = enabled && hasPin;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_needsSetup) return const PinScreen(isSettingUp: true);
    if (_requiresPin) return const PinScreen(isSettingUp: false);
    return const MainNav();
  }
}
