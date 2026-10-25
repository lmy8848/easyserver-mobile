import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  late final SharedPreferences _prefs;
  Future<void>? _initFuture;

  /// 幂等初始化（缓存首次的 Future，并发调用安全）：
  /// settingsStorageProvider 同步返回实例，读取前必须先 await 本方法，
  /// 否则 late _prefs 未就绪会抛 LateInitializationError。
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String getString(String key, {String defaultValue = ''}) =>
      _prefs.getString(key) ?? defaultValue;
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
}
