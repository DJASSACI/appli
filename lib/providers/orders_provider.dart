import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService apiService = ApiService();

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get(endpointOrders);
      if (response.statusCode == 200) {
        _orders = (response.data as List).map((json) => Order.fromJson(json)).toList();
      } else {
        _error = 'Erreur serveur: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Erreur connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSellerOrders(String sellerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/api/orders/seller/$sellerId');
      if (response.statusCode == 200) {
        _orders = (response.data as List).map((json) => Order.fromJson(json)).toList();
      } else {
        _error = 'Erreur serveur: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Erreur connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markDelivered(int orderId) async {
    try {
      await apiService.put('/api/orders/$orderId/deliver');
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> confirmDelivery(int orderId) async {
    try {
      await apiService.put('/api/orders/$orderId/confirm-delivery');
      notifyListeners();
    } catch (e) {
      throw e; // Let caller handle error
    }
  }

  Future<void> fetchMyOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/api/orders/my');
      if (response.statusCode == 200) {
        _orders = (response.data as List).map((json) => Order.fromJson(json)).toList();
      } else {
        _error = 'Erreur serveur: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Erreur connexion: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markReceived(int orderId) async {
    try {
      await apiService.put('/api/orders/$orderId/received');
      await fetchMyOrders(); // Refresh orders
    } catch (e) {
      throw e; // Let caller handle error
    }
  }
}
