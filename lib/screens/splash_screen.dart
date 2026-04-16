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
    
    // Show logo briefly
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    try {
      // Wait for full auth restoration (no timeout - ensure complete)
      await authProvider.loadCurrentUser();
      
      // Also preload products for smoother home screen
      final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
      await productsProvider.fetchProducts();
      
      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (authProvider.isAuthenticated) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        }
      });
    } catch (e) {
      // Auth failed → login screen
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
      }
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
