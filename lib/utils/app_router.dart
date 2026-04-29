import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/sell_screen.dart';
import '../screens/seller_screen.dart';
import '../screens/my_products_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/my_seller_orders_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/seller_detail_screen.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/privacy_policy_screen.dart';

// Router configuration
final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/product/:id',
      builder: (context, state) => const ProductDetailScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/sell',
      builder: (context, state) => const SellScreen(),
    ),
    GoRoute(
      path: '/seller/:name',
      builder: (context, state) {
        final name = state.pathParameters['name']!;
        return SellerScreen(sellerName: name);
      },
    ),
    GoRoute(
      path: '/my-products',
      builder: (context, state) => const MyProductsScreen(),
    ),
    GoRoute(
      path: '/my-orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '/my-seller-orders',
      builder: (context, state) => const MySellerOrdersScreen(),
    ),
    GoRoute(
      path: '/order-detail',
      builder: (context, state) {
        final order = state.extra as Order;
        return OrderDetailScreen(order: order);
      },
    ),
    GoRoute(
      path: '/seller-detail',
      builder: (context, state) {
        final data = state.extra as Map<String, String>;
        return SellerDetailScreen(
          sellerNom: data['sellerNom'] ?? 'Vendeur',
          sellerCompte: data['sellerCompte'] ?? '',
          sellerLocalisation: data['sellerLocalisation'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/chat/:otherUserId',
      builder: (context, state) {
        final otherUserId = int.parse(state.pathParameters['otherUserId']!);
        return ChatScreen(
          otherUserId: otherUserId,
          otherUserName: (state.extra as Map<String, dynamic>?)?['name'] ?? 'Utilisateur',
        );
      },
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If authenticated and on auth pages, redirect to home
    if (authProvider.isAuthenticated && 
        (state.uri.path == '/login' || state.uri.path == '/register')) {
      return '/home';
    }
    // If not authenticated and not on auth pages, redirect to login
    if (!authProvider.isAuthenticated && 
        state.uri.path != '/login' && 
        state.uri.path != '/register' && 
        state.uri.path != '/splash' &&
        state.uri.path != '/privacy-policy') {
      return '/login';
    }
    return null;
  },
);
