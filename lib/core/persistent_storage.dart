import 'package:shared_preferences/shared_preferences.dart';

enum PersistentDataKey { firstRun, userToken, userUuid, userNickname }

class PersistentStorage {
  late final SharedPreferences _instance;

  Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
    // ios에서 secure storage를 앱 삭제 후에도 남아있어 로그인이 유지되는 현상을 해결하기 위한 조치
    if (read(PersistentDataKey.firstRun) ?? false) return;
    await write(PersistentDataKey.firstRun, true);
  }

  Future<void> write<T>(PersistentDataKey key, T value) async {
    if (value is String) {
      await _instance.setString(key.name, value);
    } else if (value is int) {
      await _instance.setInt(key.name, value);
    } else if (value is double) {
      await _instance.setDouble(key.name, value);
    } else if (value is bool) {
      await _instance.setBool(key.name, value);
    } else if (value is List<String>) {
      await _instance.setStringList(key.name, value);
    } else {
      throw Exception('Unsupported type');
    }
  }

  T? read<T>(PersistentDataKey key) {
    if (T == String) {
      return _instance.getString(key.name) as T?;
    } else if (T == int) {
      return _instance.getInt(key.name) as T?;
    } else if (T == double) {
      return _instance.getDouble(key.name) as T?;
    } else if (T == bool) {
      return _instance.getBool(key.name) as T?;
    } else if (T == List<String>) {
      return _instance.getStringList(key.name) as T?;
    } else {
      throw Exception('Unsupported type');
    }
  }

  Future<void> remove(PersistentDataKey key) async {
    await _instance.remove(key.name);
  }

  Future<void> clear() async {
    await _instance.clear();
  }
}
