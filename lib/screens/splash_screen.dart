import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Step 1: Instantly restore session from local storage (no API call)
    await authProvider.loadUserFromStorage();
    
    // Step 2: Show logo briefly  
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // Step 3: Navigate immediately based on local session (NO waiting for API)
    // The user is considered authenticated as soon as local data is restored
    if (authProvider.isAuthenticated) {
      // Navigate to home immediately - local session exists
      _navigateToHome(authProvider);
    } else {
      // No local session - go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _navigateToHome(AuthProvider authProvider) {
    // Navigate to home immediately, then refresh in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/home');
        // Background sync after navigation (non-blocking)
        _syncUserInBackground(authProvider);
      }
    });
  }

  Future<void> _syncUserInBackground(AuthProvider authProvider) async {
    try {
      // Optional background sync - does NOT block navigation
      await authProvider.refreshUserInBackground();
    } catch (e) {
      // Silently ignore errors - user stays logged in with local data
      print('Background sync failed (non-blocking): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/djassaci_logo_final.svg',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            const Text(
              'DJASSACI',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plateforme E-commerce CI',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
          ],
        ),
      ),
    );
  }
}
