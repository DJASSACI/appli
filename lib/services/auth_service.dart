import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final StorageService storageService = StorageService();

  AuthService(this.apiService);

  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String numero,
    required String address,
    required String password,
  }) async {
    final response = await apiService.post(endpointAuthRegister, data: {
      'nom': nom,
      'prenom': prenom,
      'numero': numero,
      'address': address,
      'password': password,
    });

if (response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      await _saveToken(data['token']);
      // Save user data locally for session persistence
      if (data['user'] != null) {
        await storageService.saveUserData(data['user'] as Map<String, dynamic>);
      }
      return data;
    }
    throw Exception('Registration failed');
  }

  Future<Map<String, dynamic>> login({
    required String numero,
    required String password,
  }) async {
    final response = await apiService.post(endpointAuthLogin, data: {
      'numero': numero,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;

      // Save token and configure API service
      await _saveToken(token);
      apiService.setToken(token);


      // Save user data locally for session persistence
      if (data['user'] != null) {
        await storageService.saveUserData(data['user'] as Map<String, dynamic>);
      }

      // Save FCM token (non-blocking)
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        print("FCM TOKEN = $token");
        if (token != null) {
          await apiService.put('/api/users/fcm-token', data: {'fcmToken': token});
        }
      } catch (e) {
        print('FCM token save error (non-blocking): $e');
      }
      

      
      return data;
    }
    // Propagate backend error (ex: 401 { message: 'Mot de passe incorrect' })
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final msg = (data['message'] ?? data['error']);
      if (msg is String && msg.trim().isNotEmpty) {
        throw Exception(msg);
      }
    }
    throw Exception('Login failed');
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      apiService.setToken(token);

      final response = await apiService.get(endpointAuthMe);
      if (response.statusCode == 200) {
        return User.fromJson(response.data['user']);
      }

      // For any non-200, keep session behavior non-blocking.
      return null;
    } catch (_) {
      // IMPORTANT: treat /api/auth/me errors (401/404/token invalid) as a non-blocking failure.
      // Caller decides whether to keep local user.
      return null;
    }
  }


  Future<Map<String, dynamic>> refreshToken() async {
    final response = await apiService.post(endpointAuthRefresh);
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      await _saveToken(data['token']);
      return data;
    }
    throw Exception('Token refresh failed');
  }

Future<void> logout() async {
    await storage.delete(key: 'token');
    await storageService.clearUserData();
    apiService.setToken('');
  }

/// Get user from local storage without API call (for instant session restore)
  /// Also restores the token to ApiService for API calls
  Future<User?> getUserFromLocalStorage() async {
    final userData = await storageService.getUserData();
    if (userData == null) return null;
    
    // Restore token to ApiService for persistent session
    final token = await _getToken();
    if (token != null) {
      apiService.setToken(token);
    }
    
    return User.fromJson(userData);
  }

  /// Check if user data exists in local storage
  Future<bool> hasLocalUser() async {
    return await storageService.hasUserData();
  }

  /// Get token from local storage for manual restoration
  Future<String?> getTokenFromStorage() async {
    return await _getToken();
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> _saveToken(String token) async {
    await storage.write(key: 'token', value: token);
  }
}

