import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final AuthService authService;

  AuthProvider(this.authService);

  Future<bool> login(String numero, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await authService.login(numero: numero, password: password);
      authService.apiService.setToken(data['token']);
      _user = User.fromJson(data['user']);
      return true;
    } catch (e) {
      final msg = e.toString().toLowerCase();

      // Examples:
      // - "Mot de passe incorrect" (401)
      // - "Compte introuvable" (ex: 404) / or similar backend messages
      final isAccountNotFound = msg.contains('compte') && (msg.contains('introuv') || msg.contains('not found') || msg.contains('absent'));
      if (isAccountNotFound) {
        _error = 'compte introuvable';
        return false;
      }

      if (msg.contains('mot de passe') || msg.contains('password') || msg.contains('incorrect') || msg.contains('credential')) {
        _error = 'Mot de passe incorrect';
        return false;
      }

      _error = 'Mot de passe ou numéro incorrect';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String numero,
    required String address,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await authService.register(
        nom: nom,
        prenom: prenom,
        numero: numero,
        address: address,
        password: password,
      );
      authService.apiService.setToken(data['token']);
      _user = User.fromJson(data['user']);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== Methods referenced by splash/main =====

  Future<void> loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final localUser = await authService.getUserFromLocalStorage();
      _user = localUser;
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get hasLocalSession => _user != null;

  Future<bool> hasLocalSessionAsync() async {
    return await authService.hasLocalUser();
  }

  void setUserFromSession(Map<String, dynamic> userData) {
    _user = User.fromJson(userData);
    notifyListeners();
  }

  Future<void> refreshUserInBackground() async {
    try {
      final freshUser = await authService.getCurrentUser();
      if (freshUser == null) return;

      _user = freshUser;
      notifyListeners();

      // Persist user data if desired
      await authService.storageService.saveUserData(freshUser.toJson());
    } catch (_) {
      // non-blocking
    }
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await authService.getCurrentUser();
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

