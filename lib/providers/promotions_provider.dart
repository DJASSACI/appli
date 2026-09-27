import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PromotionsProvider with ChangeNotifier {
  List<Promotion> _promotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = false;
  String? _error;

  List<Promotion> get promotions => _promotions;
  List<Promotion> get filteredPromotions => _filteredPromotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService apiService = ApiService();

  Future<void> fetchPromotions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/api/promotions');
      if (response.statusCode == 200) {
        final allPromotions = (response.data as List)
            .map((json) => Promotion.fromJson(json))
            .toList();
        _promotions = allPromotions.where((p) => p.isActive == true).toList();

        _promotions.sort((a, b) {
          if (a.datePublication == null && b.datePublication == null) return 0;
          if (a.datePublication == null) return 1;
          if (b.datePublication == null) return -1;
          try {
            return DateTime.parse(b.datePublication.toString())
                .compareTo(DateTime.parse(a.datePublication.toString()));
          } catch (_) {
            return 0;
          }
        });

        _filteredPromotions = List.from(_promotions);
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

  void searchPromotions(String query) {
    if (query.isEmpty) {
      _filteredPromotions = List.from(_promotions);
    } else {
      _filteredPromotions = _promotions.where((promotion) =>
        promotion.name.toLowerCase().contains(query.toLowerCase()) ||
        promotion.description.toLowerCase().contains(query.toLowerCase()) ||
        promotion.categorie.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  void filterByCategory(String category) {
    if (category.isEmpty) {
      _filteredPromotions = List.from(_promotions);
    } else {
      _filteredPromotions = _promotions.where((promotion) =>
        promotion.categorie.toLowerCase() == category.toLowerCase()
      ).toList();
    }
    notifyListeners();
  }
}