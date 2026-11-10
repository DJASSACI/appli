import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback de tap sur une notification locale (payload JSON décodé).
typedef LocalNotificationTapCallback = void Function(Map<String, dynamic> data);

/// Handler background pour le clic notification locale (isolate séparé).
/// Doit rester top-level + entry-point ; ne navigue pas directement.
@pragma('vm:entry-point')
void localNotificationBackgroundTap(NotificationResponse response) {
  // Aucun routage ici (isolate background). Le lancement via notification
  // est traité au démarrage (getNotificationAppLaunchDetails).
}

/// Service singleton encapsulant le plugin de notifications locales.
/// L'instance FlutterLocalNotificationsPlugin est injectée depuis main.dart
/// pour réutiliser l'initialisation et le canal Android déjà créés.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  FlutterLocalNotificationsPlugin? _plugin;
  LocalNotificationTapCallback? onTap;
  // (P6) Empêche le double traitement du même payload au lancement (launch details
  // + callback réponse). Ne bloque pas les clics ultérieurs sur d'autres notifications.
  String? _lastHandledLaunchKey;
  int _lastHandledLaunchMs = 0;

  FlutterLocalNotificationsPlugin get plugin => _plugin!;

  /// Enregistre l'instance déjà initialisée dans main.dart.
  void setPlugin(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  /// Initialise les callbacks de clic (flutter_local_notifications v18).
  /// À appeler après [initialize] si besoin, ou utiliser [initWithTap].
  Future<void> initWithTap(LocalNotificationTapCallback onTapCallback) async {
    if (_plugin == null) return;
    onTap = onTapCallback;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin!.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: localNotificationBackgroundTap,
    );
  }

  /// Traite un lancement depuis une notification locale (app fermée/terminée).
  Future<void> handleAppLaunchFromLocalNotification() async {
    if (_plugin == null) return;
    try {
      final details = await _plugin!.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response != null) {
        _onResponse(response, fromLaunch: true);
      }
    } catch (_) {}
  }

  void _onResponse(NotificationResponse response, {bool fromLaunch = false}) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    // (P6) garde one-shot court : même id/payload au démarrage traité une seule fois.
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = '${response.id ?? 'na'}|${response.actionId ?? ''}|$payload';
    if (fromLaunch || (now - _lastHandledLaunchMs) < 3000) {
      if (_lastHandledLaunchKey == key) return;
    }
    if (fromLaunch || key == _lastHandledLaunchKey) {
      _lastHandledLaunchKey = key;
      _lastHandledLaunchMs = now;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        onTap?.call(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  /// Affiche une notification locale de bienvenue dans la barre de notifications Android.
  /// (Conservé — comportement existant.)
  Future<void> showWelcomeNotification() async {
    if (_plugin == null) {
      return;
    }
    await _plugin!.show(
      0,
      'Bienvenue sur DJASSACI',
      'Découvrez nos produits et contactez facilement les vendeurs.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'djassaci_channel',
          'Djassaci Notifications',
          channelDescription: 'Channel for Djassaci app notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
