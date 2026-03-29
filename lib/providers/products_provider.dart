import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService apiService = ApiService();

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get(endpointProducts);
      if (response.statusCode == 200) {
        _products = (response.data as List).map((json) => Product.fromJson(json)).toList();
        _filteredProducts = List.from(_products);
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

  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.description.toLowerCase().contains(query.toLowerCase()) ||
        product.categorie.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  void filterByCategory(String category) {
    if (category.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) =>
        product.categorie.toLowerCase() == category.toLowerCase()
      ).toList();
    }
    notifyListeners();
  }
}

