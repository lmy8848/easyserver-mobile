import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getBool(String key, {bool defaultValue = false}) => _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String getString(String key, {String defaultValue = ''}) => _prefs.getString(key) ?? defaultValue;
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  int getInt(String key, {int defaultValue = 0}) => _prefs.getInt(key) ?? defaultValue;
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
}
