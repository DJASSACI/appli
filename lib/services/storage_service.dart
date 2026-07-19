import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userDataKey = 'user_data';
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
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

  // User data for local session (SharedPreferences)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final p = await prefs;
    await p.setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final p = await prefs;
    final String? data = p.getString(_userDataKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearUserData() async {
    final p = await prefs;
    await p.remove(_userDataKey);
  }

  Future<bool> hasUserData() async {
    final p = await prefs;
    return p.containsKey(_userDataKey);
  }

  // Local prefs for cart, etc.
  Future<void> setInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final p = await prefs;
    return p.getInt(key);
  }

  // etc for other types
}

