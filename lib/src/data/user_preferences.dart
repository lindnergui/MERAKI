import 'package:shared_preferences/shared_preferences.dart';

/// Small local store for the non-sensitive display name used by the UI.
class UserPreferences {
  static const String _userNameKey = 'userName';
  static const String _favoriteSongIdsKey = 'favoriteSongIds';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<String?> readUserName() async {
    final userName = (await _preferences.getString(_userNameKey))?.trim();
    return userName == null || userName.isEmpty ? null : userName;
  }

  Future<void> saveUserName(String userName) {
    return _preferences.setString(_userNameKey, userName.trim());
  }

  Future<void> clearUserName() => _preferences.remove(_userNameKey);

  Future<Set<String>> readFavoriteSongIds() async {
    final ids = await _preferences.getStringList(_favoriteSongIdsKey);
    return ids == null ? <String>{} : ids.toSet();
  }

  Future<void> saveFavoriteSongIds(Set<String> songIds) {
    return _preferences.setStringList(
      _favoriteSongIdsKey,
      songIds.toList(growable: false),
    );
  }
}
