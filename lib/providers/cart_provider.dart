import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  static const String _cartKey = 'cart_items';
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + (item.quantity * item.product.price));

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_cartKey);
    if (saved != null) {
      for (final jsonStr in saved) {
        try {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          _items.add(CartItem.fromJson(decoded));
        } catch (_) {
          // ignore malformed entries
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_cartKey, encoded);
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
    _saveCart();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(int productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0 && newQuantity > 0) {
      _items[index].quantity = newQuantity;
      notifyListeners();
      _saveCart();
    } else if (newQuantity <= 0) {
      removeItem(productId);
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }
}