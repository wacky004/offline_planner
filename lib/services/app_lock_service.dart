import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginType { pattern, pin, password }

class AppLockService {
  static const String _hasCompletedSetupKey = 'has_completed_security_setup';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _loginTypeKey = 'login_type';
  static const String _storedCredentialKey = 'stored_credential';
  static const String _securityQuestionKey = 'security_question';
  static const String _securityAnswerKey = 'security_answer';

  // Has the user completed the initial setup flow?
  Future<bool> hasCompletedSetup() async {
    final prefs = await SharedPreferences.getInstance();
    // For migration: if pin is enabled and setup is false, gracefully handle it
    final legacyPinEnabled = prefs.getBool('pin_enabled') ?? false;
    final hasSetup = prefs.getBool(_hasCompletedSetupKey) ?? false;
    
    // If they have legacy pin but no new setup, we still need them to complete setup to choose a question.
    // However, if we want to migrate, we can treat them as not having setup so they get prompted.
    return hasSetup;
  }

  // Is App Lock currently enabled?
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false, check legacy pin if null
    final appLock = prefs.getBool(_appLockEnabledKey);
    if (appLock == null) {
      // Migrate legacy pin enabled state
      final legacyPinEnabled = prefs.getBool('pin_enabled') ?? false;
      return legacyPinEnabled;
    }
    return appLock;
  }

  Future<void> toggleAppLock(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_loginTypeKey);
    if (typeStr == null) {
        // Migration: defaults to PIN if they had a legacy PIN setup
        if (prefs.getString('user_pin') != null) {
            return LoginType.pin;
        }
        return LoginType.pin;
    }
    return LoginType.values.firstWhere((e) => e.toString() == typeStr, orElse: () => LoginType.pin);
  }

  Future<String?> getSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_securityQuestionKey);
  }

  // Helper to hash answers/passwords for basic local security
  String _hashString(String input) {
    final bytes = utf8.encode(input.toLowerCase().trim()); // Case-insensitive for answer
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  String _hashCredential(String input) {
    final bytes = utf8.encode(input); 
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyCredential(String credential) async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_storedCredentialKey);
    
    // Migration: verify against legacy PIN
    if (storedKey == null) {
        final legacyPin = prefs.getString('user_pin');
        if (legacyPin != null && legacyPin == credential) {
            return true;
        }
        return false;
    }

    final hashedInput = _hashCredential(credential);
    return storedKey == hashedInput;
  }

  Future<bool> verifySecurityAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    final storedAnswer = prefs.getString(_securityAnswerKey);
    if (storedAnswer == null) return false;

    final hashedInput = _hashString(answer);
    return storedAnswer == hashedInput;
  }

  Future<void> saveSetup({
    required String question,
    required String answer,
    required LoginType loginType,
    required String credential,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_hasCompletedSetupKey, true);
    await prefs.setBool(_appLockEnabledKey, true);
    await prefs.setString(_loginTypeKey, loginType.toString());
    
    await prefs.setString(_securityQuestionKey, question);
    await prefs.setString(_securityAnswerKey, _hashString(answer));
    
    await prefs.setString(_storedCredentialKey, _hashCredential(credential));
    
    // Clear legacy to avoid confusion
    await prefs.remove('user_pin');
    await prefs.remove('pin_enabled');
  }

  Future<void> updateCredential(LoginType loginType, String credential) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loginTypeKey, loginType.toString());
      await prefs.setString(_storedCredentialKey, _hashCredential(credential));
  }
  
  Future<void> updateSecurityQuestion(String question, String answer) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_securityQuestionKey, question);
      await prefs.setString(_securityAnswerKey, _hashString(answer));
  }

  Future<void> removeLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, false);
  }
}
