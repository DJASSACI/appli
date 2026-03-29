// Constants for Djassa CI Flutter App

import 'package:flutter/material.dart';

const String appName = 'Djassa CI';
const String appVersion = '1.0.0';
const String baseUrl = 'http://10.0.2.2:3000';

/// API Endpoints (relative to baseUrl)
const String endpointAuthRegister = '/api/auth/register';
const String endpointAuthLogin = '/api/auth/login';
const String endpointAuthMe = '/api/auth/me';
const String endpointAuthRefresh = '/api/auth/refresh';
const String endpointProducts = '/api/products';
const String endpointProductsId = '/api/products/';
const String endpointProductsCategory = '/api/products/category/';
const String endpointProductsSearch = '/api/products/search/';
const String endpointOrders = '/api/orders';
const String endpointOrdersMy = '/api/orders/my';
const String endpointOrdersId = '/api/orders/';
const String endpointUsersProfile = '/api/users/profile';
const String endpointArticles = '/api/articles';
const String endpointContact = '/api/contact';
const String endpointHealth = '/api/health';
const String endpointStats = '/api/stats';

/// Colors
const primaryColor = Color(0xFF6C5CE7);
const secondaryColor = Color(0xFFFF7675);
const accentColor = Color(0xFFFFD93D);
const backgroundColor = Color(0xFFF8F9FA);
const cardColor = Colors.white;

/// Currency
const String currencySymbol = 'FCFA';

/// Categories (from backend defaults)
const List<String> categories = [
  'Téléphones',
  'Ordinateurs', 
  'Audio',
  'Accessoires',
  'Tablettes',
  'Montres',
  'TV',
  'Électroménager',
  'Autre'
];

