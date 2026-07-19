import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'utils/theme.dart';
import 'utils/app_router.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'providers/products_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'providers/chat_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialize auth session from local storage before app starts
/// This enables instant login restoration without API calls
/// Corriger pour: récupère automatiquement le token depuis FlutterSecureStorage
/// et restaure les données utilisateur depuis SharedPreferences
Future<Map<String, dynamic>?> initializeSession() async {
  final secureStorage = const FlutterSecureStorage();
  
  try {
    // 1. Get token from FlutterSecureStorage
    final token = await secureStorage.read(key: 'token');
    
    if (token != null && token.isNotEmpty) {
      // 2. Inject token into ApiService IMMEDIATELY before any API call
      ApiService.instance.setToken(token);
      print('✅ Session restored: Token injected into ApiService');
      
      // 3. Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        // Parse user data JSON
        final userData = jsonDecode(userDataString);
        print('✅ Session restored: User data loaded from local storage');
        
        return {
          'token': token,
          'user': userData,
        };
      }
      
      // Token exists but no user data - user still authenticated
      print('✅ Session restored: Token exists, no user data yet');
      return {
        'token': token,
        'user': null,
      };
    }
    
    print('ℹ️ No local session: No token found');
  } catch (e) {
    print('Session initialization error: $e');
  }
  
  return null;
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();





  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await firebase_auth.FirebaseAuth.instance.signInAnonymously();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );


  String? token = await FirebaseMessaging.instance.getToken();

  if (token == null || token.isEmpty) {
    print("❌ TOKEN FCM INVALID");
  } else {
    print("✅ TOKEN OK: $token");
  }


  // Save token to backend
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification ouverte');
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  // Restore session BEFORE running app
  final sessionData = await initializeSession();
  
  runApp(MyApp(initialSession: sessionData));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialSession;
  
  const MyApp({super.key, this.initialSession});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider(AuthService(ApiService()));
            // If we have a restored session, set user immediately
            if (initialSession != null && initialSession!['user'] != null) {
              provider.setUserFromSession(Map<String, dynamic>.from(initialSession!['user']));
            }
            return provider;
          }
        ),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],

      child: MaterialApp.router(
        title: 'Djassa CI',
        theme: appTheme(),
        routerConfig: router,
      ),
    );
  }
}

