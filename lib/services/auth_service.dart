import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

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
      await _saveToken(data['token']);
      return data;
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
    } catch (e) {
      return null;
    }
    return null;
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
    apiService.setToken('');
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> _saveToken(String token) async {
    await storage.write(key: 'token', value: token);
  }
}

