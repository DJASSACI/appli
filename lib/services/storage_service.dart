import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late final SharedPreferences prefs;

  StorageService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Secure storage for tokens
  Future<void> setSecureString(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecureString(String key) async {
    return await secureStorage.read(key: key);
  }

  Future<void> deleteSecureString(String key) async {
    await secureStorage.delete(key: key);
  }

  Future<void> deleteAllSecure() async {
    await secureStorage.deleteAll();
  }

  // Local prefs for cart, etc.
  Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return prefs.getInt(key);
  }

  // etc for other types
}

