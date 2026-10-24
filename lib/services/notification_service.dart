import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service de gestion du compteur de notifications de commandes et promotions non lues.
/// Stocke l'état localement et notifie l'UI via des ValueNotifier.
class NotificationService {
  static const String _orderUnreadKey = 'order_unread_count';
  static const String _promoUnreadKey = 'promo_unread_count';
  static const String _orderNotifIdsKey = 'order_notif_ids';
  static const String _promoNotifIdsKey = 'promo_notif_ids';

  /// Notifier pour le badge des commandes (utilisé par HomeScreen).
  static final ValueNotifier<int> orderUnreadNotifier = ValueNotifier<int>(0);
  /// Notifier pour le badge des promotions (utilisé par HomeScreen).
  static final ValueNotifier<int> promoUnreadNotifier = ValueNotifier<int>(0);

  /// Initialise les notifiers depuis le stockage local.
  static Future<void> initNotifiers() async {
    final count = await NotificationService().getOrderUnreadCount();
    orderUnreadNotifier.value = count;
    final promoCount = await NotificationService().getPromoUnreadCount();
    promoUnreadNotifier.value = promoCount;
  }

  /// Traite un message Firebase reçu (premier plan, arrière-plan, réouverture).
  /// Déduit l'ID de notification et appelle la méthode appropriée selon le type.
  /// Retourne true si le compteur a été modifié.
  static Future<bool> processFirebaseMessage(RemoteMessage message) async {
    final type = message.data['type'] ?? '';
    final notifId = _generateNotifId(message);

    if (type == 'promotion') {
      final service = NotificationService();
      final ids = await service._getPromoNotifIds();
      if (!ids.contains(notifId)) {
        await service.addPromoNotification(notifId);
        return true;
      }
    } else if (type == 'payment_confirmed' || type == 'payment_failed' || type == 'order_confirmed') {
      final service = NotificationService();
      final ids = await service._getOrderNotifIds();
      if (!ids.contains(notifId)) {
        await service.addOrderNotification(notifId);
        return true;
      }
    }
    return false;
  }

  /// Génère un identifiant unique pour un message Firebase.
  /// Priorité : promotionId/orderId + type + timestamp, sinon message ID, sinon hash.
  static String _generateNotifId(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    final id = data['promotionId'] ?? data['orderId'] ?? '';
    final sentTime = message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    if (id.isNotEmpty) {
      return '${type}_${id}_$sentTime';
    }
    return message.messageId ?? 'notif_$sentTime';
  }

  Future<List<String>> _getPromoNotifIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_promoNotifIdsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _getOrderNotifIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_orderNotifIdsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  // ===== Commandes =====

  /// Récupère le nombre de notifications de commande non lues.
  Future<int> getOrderUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_orderUnreadKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Incrémente le compteur de notifications de commande non lues.
  Future<void> incrementOrderUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_orderUnreadKey) ?? 0;
      await prefs.setInt(_orderUnreadKey, current + 1);
      orderUnreadNotifier.value = current + 1;
    } catch (_) {}
  }

  /// Réinitialise le compteur de notifications de commande non lues.
  Future<void> resetOrderUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderUnreadKey);
      await prefs.remove(_orderNotifIdsKey);
      orderUnreadNotifier.value = 0;
    } catch (_) {}
  }

  /// Enregistre une notification de commande comme non lue (sans doublon).
  Future<void> addOrderNotification(String notifId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_orderNotifIdsKey) ?? [];
      if (!ids.contains(notifId)) {
        ids.add(notifId);
        await prefs.setStringList(_orderNotifIdsKey, ids);
        final current = prefs.getInt(_orderUnreadKey) ?? 0;
        await prefs.setInt(_orderUnreadKey, current + 1);
        orderUnreadNotifier.value = current + 1;
      }
    } catch (_) {}
  }

  /// Marque une notification de commande comme lue (décrémenter le compteur).
  Future<void> markOrderNotificationRead(String notifId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_orderNotifIdsKey) ?? [];
      if (ids.contains(notifId)) {
        ids.remove(notifId);
        await prefs.setStringList(_orderNotifIdsKey, ids);
        final current = prefs.getInt(_orderUnreadKey) ?? 0;
        final newCount = current > 0 ? current - 1 : 0;
        await prefs.setInt(_orderUnreadKey, newCount);
        orderUnreadNotifier.value = newCount;
      }
    } catch (_) {}
  }

  // ===== Promotions =====

  /// Récupère le nombre de notifications de promotion non lues.
  Future<int> getPromoUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_promoUnreadKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Incrémente le compteur de notifications de promotion non lues.
  Future<void> incrementPromoUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_promoUnreadKey) ?? 0;
      await prefs.setInt(_promoUnreadKey, current + 1);
      promoUnreadNotifier.value = current + 1;
    } catch (_) {}
  }

  /// Réinitialise le compteur de notifications de promotion non lues.
  Future<void> resetPromoUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promoUnreadKey);
      await prefs.remove(_promoNotifIdsKey);
      promoUnreadNotifier.value = 0;
    } catch (_) {}
  }

  /// Enregistre une notification de promotion comme non lue (sans doublon).
  Future<void> addPromoNotification(String notifId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_promoNotifIdsKey) ?? [];
      if (!ids.contains(notifId)) {
        ids.add(notifId);
        await prefs.setStringList(_promoNotifIdsKey, ids);
        final current = prefs.getInt(_promoUnreadKey) ?? 0;
        await prefs.setInt(_promoUnreadKey, current + 1);
        promoUnreadNotifier.value = current + 1;
      }
    } catch (_) {}
  }

  /// Marque une notification de promotion comme lue (décrémenter le compteur).
  Future<void> markPromoNotificationRead(String notifId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_promoNotifIdsKey) ?? [];
      if (ids.contains(notifId)) {
        ids.remove(notifId);
        await prefs.setStringList(_promoNotifIdsKey, ids);
        final current = prefs.getInt(_promoUnreadKey) ?? 0;
        final newCount = current > 0 ? current - 1 : 0;
        await prefs.setInt(_promoUnreadKey, newCount);
        promoUnreadNotifier.value = newCount;
      }
    } catch (_) {}
  }

  /// Marque toutes les notifications de promotion comme lues.
  Future<void> markAllPromoRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promoUnreadKey);
      await prefs.remove(_promoNotifIdsKey);
      promoUnreadNotifier.value = 0;
    } catch (_) {}
  }

  /// Marque toutes les notifications de commande comme lues.
  Future<void> markAllOrderRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderUnreadKey);
      await prefs.remove(_orderNotifIdsKey);
      orderUnreadNotifier.value = 0;
    } catch (_) {}
  }
}