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
        final allProducts = (response.data as List).map((json) => Product.fromJson(json)).toList();
        _products = allProducts
            .where((p) => p.isActive == true)
            .toList();

        // Tri: garder les plus récents en haut (utilise uniquement les champs présents côté backend)
        // Backend utilise généralement `datePublication`. On fallback sur `date` si nécessaire.
        _products.sort((a, b) {
          final da = a.datePublication ?? (a as dynamic).date ?? (a as dynamic).created_at;
          final db = b.datePublication ?? (b as dynamic).date ?? (b as dynamic).created_at;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          try {
            return DateTime.parse(db.toString()).compareTo(DateTime.parse(da.toString()));
          } catch (_) {
            return 0;
          }
        });


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

