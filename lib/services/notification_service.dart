import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/app_router.dart';
import 'api_service.dart';

/// Gestion compteurs/badges notifications + routage clic FCM/local (additif).
/// Préserve les notifiers/clefs existants (promotions, commandes).
class NotificationService {
  static const String _orderUnreadKey = 'order_unread_count';
  static const String _promoUnreadKey = 'promo_unread_count';
  static const String _orderNotifIdsKey = 'order_notif_ids';
  static const String _promoNotifIdsKey = 'promo_notif_ids';
  static const String _fcmTokenSentKey = 'fcm_token_last_sent';

  /// Notifier pour le badge des commandes (utilisé par HomeScreen).
  static final ValueNotifier<int> orderUnreadNotifier = ValueNotifier<int>(0);
  /// Notifier pour le badge des promotions (utilisé par HomeScreen).
  static final ValueNotifier<int> promoUnreadNotifier = ValueNotifier<int>(0);

  /// Intention de navigation différée (notif cliquée alors que l'utilisateur
  /// n'est pas authentifié). Consommée après connexion réussie.
  /// Limite (P2) : conservée en mémoire uniquement ; perdue si le process
  /// Android est tué avant authentification.
  static String? _pendingRoute;
  static String? get pendingRoute => _pendingRoute;
  static void setPendingRoute(String? route) => _pendingRoute = route;
  static void clearPendingRoute() => _pendingRoute = null;

  /// Invalide le cache local de sync token FCM (P4 : changement de compte
  /// sur le même appareil). Ne supprime PAS le token FCM Firebase.
  /// À appeler au logout et juste après login/register réussi avant resync.
  static Future<void> invalidateFcmTokenSyncCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenSentKey);
    } catch (_) {}
  }

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
    final type = (message.data['type'] ?? '').toString();
    final notifId = _generateNotifId(message);
    final service = NotificationService();

    if (type == 'promotion') {
      final ids = await service._getPromoNotifIds();
      if (!ids.contains(notifId)) {
        await service.addPromoNotification(notifId);
        return true;
      }
      return false;
    }

    // Types existants commandes/paiement + nouveaux types team/savings/compat
    // qui portent un impact "commande/activité" côté utilisateur.
    const orderLikeTypes = <String>{
      'payment_confirmed',
      'payment_failed',
      'order_confirmed',
      'team_created',
      'team_participant_joined',
      'team_contribution_initiated',
      'team_contribution_confirmed',
      'team_contribution_failed',
      'team_goal_reached',
      'team_order_created',
      'team_purchase_completed',
      'savings_plan_created',
      'savings_contribution_initiated',
      'savings_contribution_confirmed',
      'savings_contribution_failed',
      'savings_goal_reached',
      'savings_order_created',
      'promotion_savings_completed',
    };
    if (orderLikeTypes.contains(type)) {
      final ids = await service._getOrderNotifIds();
      if (!ids.contains(notifId)) {
        await service.addOrderNotification(notifId);
        return true;
      }
    }
    return false;
  }

  /// Génère un identifiant unique pour un message Firebase (dédup additive).
  /// Inclut teamId/planId/contributionId en plus des clés existantes pour éviter
  /// les collisions entre événements team/savings ; préserve promotion/order.
  static String _generateNotifId(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    final id = (data['promotionId'] ??
            data['orderId'] ??
            data['teamId'] ??
            data['planId'] ??
            data['contributionId'] ??
            '')
        .toString();
    final sentTime = message.sentTime?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    if (id.isNotEmpty) {
      return '${type}_${id}_$sentTime';
    }
    return message.messageId ?? 'notif_$sentTime';
  }

  /// Calcule la route cible depuis un payload de notification.
  /// Retourne null si le type n'est pas routable ou si l'identifiant est absent/invalide.
  /// Ne crée aucune route (Team/Savings existantes uniquement) ; n'invente pas de détail commande.
  static String? routeForNotificationData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    if (type.isEmpty) return null;
    const teamTypes = <String>{
      'team_created',
      'team_participant_joined',
      'team_contribution_initiated',
      'team_contribution_confirmed',
      'team_contribution_failed',
      'team_goal_reached',
      'team_order_created',
      'team_purchase_completed',
    };
    const savingsTypes = <String>{
      'savings_plan_created',
      'savings_contribution_initiated',
      'savings_contribution_confirmed',
      'savings_contribution_failed',
      'savings_goal_reached',
      'savings_order_created',
      'promotion_savings_completed',
    };
    if (teamTypes.contains(type)) {
      final id = int.tryParse((data['teamId'] ?? '').toString());
      if (id != null && id > 0) return '/team/$id';
      return null;
    }
    if (savingsTypes.contains(type)) {
      final id = int.tryParse((data['planId'] ?? '').toString());
      if (id != null && id > 0) return '/savings/$id';
      return null;
    }
    return null;
  }

  /// Gestion centralisée d'un clic notification (FCM/local).
  /// Si [isAuthenticated] est false, stocke une intention différée (appliquée
  /// après connexion) au lieu de contourner l'auth. (P3) fallback: si un JWT
  /// semble présent mais que l'appelant signale non-authentifié, on stocke aussi
  /// l'intention pour éviter une perte lors du timing JWT restauré / _user non prêt.
  static void handleNotificationTap(
    Map<String, dynamic> data, {
    required bool isAuthenticated,
  }) {
    final route = routeForNotificationData(data);
    if (route == null) return;
    if (!isAuthenticated || !ApiService.instanceHasToken()) {
      _pendingRoute = route;
      return;
    }
    _navigateWhenReady(route);
  }

  /// Consomme l'intention différée après authentification confirmée.
  static void consumePendingRouteIfAuthenticated() {
    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    _navigateWhenReady(route);
  }

  static void _navigateWhenReady(String route) {
    void go() {
      try {
        // go_router global : routes Team/Savings existent ; redirect protège l'auth.
        router.go(route);
      } catch (_) {}
    }
    // Routeur prêt après runApp/premier frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }

  /// Synchronise le token FCM vers le backend (JWT requis).
  /// Best-effort, non bloquant, anti-doublon (cache dernier token envoyé).
  /// N'affiche jamais le token dans les logs. Ne pas appeler sans JWT valide.
  static Future<void> syncFcmTokenIfAuthenticated() async {
    try {
      if (!ApiService.instanceHasToken()) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_fcmTokenSentKey);
      if (last == token) return;
      await ApiService.instance.put('/api/users/fcm-token', data: {'fcmToken': token});
      await prefs.setString(_fcmTokenSentKey, token);
    } catch (_) {
      // Non bloquant (401 si non auth, réseau, etc.).
    }
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