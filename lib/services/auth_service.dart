import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final StorageService storageService = StorageService();

  AuthService(this.apiService);

  /// Synchronisation token FCM (best-effort, JWT requis, sans log du token).
  /// (P5) Fire-and-forget par défaut : ne retarde pas login/register.
  Future<void> syncFcmTokenIfAuthenticated({bool awaitResult = false}) async {
    final f = NotificationService.syncFcmTokenIfAuthenticated();
    if (awaitResult) {
      await f;
    } else {
      unawaited(f);
    }
  }

  /// (P4) Invalide le cache de sync FCM avant resync sur un nouveau compte.
  Future<void> invalidateFcmTokenSyncCache() async {
    await NotificationService.invalidateFcmTokenSyncCache();
  }

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
      final token = data['token'] as String?;
      if (token != null) {
        await _saveToken(token);
        apiService.setToken(token);
      }
      // Save user data locally for session persistence
      if (data['user'] != null) {
        await storageService.saveUserData(data['user'] as Map<String, dynamic>);
      }
      // (P4/P5) Nouveau compte -> invalider cache sync puis resync (non bloquant).
      await invalidateFcmTokenSyncCache();
      await syncFcmTokenIfAuthenticated();
      return data;
    }
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final msg = (data['message'] ?? data['error']);
      if (msg is String && msg.trim().isNotEmpty) {
        throw Exception(msg);
      }
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

      // (P4/P5) Changement potentiel de compte -> invalider cache puis resync (non bloquant).
      await invalidateFcmTokenSyncCache();
      await syncFcmTokenIfAuthenticated();
      

      
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
        return User.fromJson(response.data);
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

  Future<Map<String, dynamic>> forgotPasswordRequest({
    required String numero,
  }) async {
    final response = await apiService.post(endpointForgotPasswordRequest, data: {
      'numero': numero,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> forgotPasswordApprove({
    required String numero,
    required String tempPassword,
  }) async {
    final response = await apiService.post(endpointForgotPasswordApprove, data: {
      'numero': numero,
      'tempPassword': tempPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String tempPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await apiService.post(endpointForgotPasswordReset, data: {
      'tempPassword': tempPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await apiService.post(endpointChangePassword, data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> _saveToken(String token) async {
    await storage.write(key: 'token', value: token);
  }
}

