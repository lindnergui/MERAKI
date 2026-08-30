import 'package:shared_preferences/shared_preferences.dart';

/// Small local store for the non-sensitive display name used by the UI.
class UserPreferences {
  static const String _userNameKey = 'userName';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<String?> readUserName() async {
    final userName = (await _preferences.getString(_userNameKey))?.trim();
    return userName == null || userName.isEmpty ? null : userName;
  }

  Future<void> saveUserName(String userName) {
    return _preferences.setString(_userNameKey, userName.trim());
  }

  Future<void> clearUserName() => _preferences.remove(_userNameKey);
}
