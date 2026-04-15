import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_lock_service.dart';
import 'security_setup_screen.dart';
import 'security_login_screen.dart';
import 'main_nav.dart';
import 'mode_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    try {
      // Artificial delay for splash visual
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final userMode = prefs.getString('user_mode');

      // Completely new install? Show onboarding.
      if (userMode == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
        );
        return;
      }

      final appLock = AppLockService();
      final hasSetup = await appLock.hasCompletedSetup();
      final lockEnabled = await appLock.isAppLockEnabled();

      if (!mounted) return;

      if (!hasSetup) {
        // Finished onboarding but no security setup yet
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SecuritySetupScreen()),
        );
      } else if (lockEnabled) {
        // Ready to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SecurityLoginScreen()),
        );
      } else {
        // Lock explicitly disabled, go to app directly
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNav()),
        );
      }
    } catch (e, stacktrace) {
      debugPrint('Error in SplashScreen _route: $e\n$stacktrace');
      if (mounted) {
        // Fallback safety to ensure user is never permanently stuck
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNav()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Offline Planner',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
