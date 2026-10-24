import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de stockage local pour l'historique des messages MAWA.
/// Les messages expirent après 1 heure.
class MawaService {
  static const String _historyKey = 'mawa_history';
  static const String _unreadKey = 'mawa_has_unread';
  static const Duration _ttl = Duration(hours: 1);

  /// Notifier pour l'état des messages non lus (utilisé par HomeScreen).
  static final ValueNotifier<bool> unreadNotifier = ValueNotifier<bool>(false);

  /// Initialise le notifier depuis le stockage local.
  static Future<void> initUnreadNotifier() async {
    final hasUnread = await MawaService().hasUnread();
    unreadNotifier.value = hasUnread;
  }

  /// Charge l'historique des messages encore valides (< 1 heure).
  Future<List<Map<String, dynamic>>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      final messages = <Map<String, dynamic>>[];
      for (final m in list) {
        if (m is! Map) continue;
        final ts = (m['ts'] as num?)?.toInt() ?? 0;
        if (ts == 0) continue;
        if (now - ts > _ttl.inMilliseconds) continue; // expiré
        messages.add(Map<String, dynamic>.from(m));
      }
      // Nettoyer les expirés
      if (messages.length < list.length) {
        await _saveHistory(messages);
      }
      return messages;
    } catch (_) {
      return [];
    }
  }

  /// Sauvegarde l'historique complet.
  Future<void> _saveHistory(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(messages));
    } catch (_) {}
  }

  /// Ajoute un message à l'historique.
  Future<void> addMessage(String role, String text) async {
    try {
      final history = await loadHistory();
      history.add({
        'role': role,
        'text': text,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      await _saveHistory(history);
    } catch (_) {}
  }

  /// Marque tous les messages comme lus.
  Future<void> markAllRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_unreadKey, false);
      unreadNotifier.value = false;
    } catch (_) {}
  }

  /// Indique s'il y a des messages non lus.
  Future<bool> hasUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_unreadKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Définit l'état des messages non lus.
  Future<void> setUnread(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_unreadKey, value);
      unreadNotifier.value = value;
    } catch (_) {}
  }

  /// Efface l'historique MAWA.
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      await prefs.remove(_unreadKey);
      unreadNotifier.value = false;
    } catch (_) {}
  }
}