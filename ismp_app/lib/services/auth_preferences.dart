import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to manage persistent login state using SharedPreferences.
/// Saves the user's email and role (student vs rep) so the app can
/// skip the login screen on subsequent launches.
class AuthPreferences {
  static const String _keyEmail = 'auth_email';
  static const String _keyIsRep = 'auth_is_rep';
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  /// Save login credentials after successful sign-in.
  static Future<void> saveLogin(String email, bool isRep) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setBool(_keyIsRep, isRep);
  }

  /// Check if a user is currently logged in.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get the saved rep status.
  static Future<bool> getIsRep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsRep) ?? false;
  }

  /// Get the saved email.
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Clear all saved auth data (used on logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyIsRep);
  }
}
