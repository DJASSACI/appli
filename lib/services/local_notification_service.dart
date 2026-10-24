import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service singleton encapsulant le plugin de notifications locales.
/// L'instance FlutterLocalNotificationsPlugin est injectée depuis main.dart
/// pour réutiliser l'initialisation et le canal Android déjà créés.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  FlutterLocalNotificationsPlugin? _plugin;

  FlutterLocalNotificationsPlugin get plugin => _plugin!;

  /// Enregistre l'instance déjà initialisée dans main.dart.
  void setPlugin(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  /// Affiche une notification locale de bienvenue dans la barre de notifications Android.
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
