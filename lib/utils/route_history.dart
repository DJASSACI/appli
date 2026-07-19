import 'package:flutter/foundation.dart';

class RouteHistory {
  static final List<String> _history = [];

  static void add(String route) {
    if (_history.isEmpty || _history.last != route) {
      _history.add(route);
    }
  }

  static String? previous() {
    if (_history.length < 2) return null;
    return _history[_history.length - 2];
  }

  static void removeLast() {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
  }
}

