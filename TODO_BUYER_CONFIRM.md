# TODO: Acheteur "Colis Reçu" + Notify Vendeur

1. ✅ [DONE] User approval
2. Créer lib/screens/my_orders_screen.dart (buyer orders list + bouton "Colis Reçu" si statut=='livraison_confirmee')
3. Ajouter route /my-orders dans lib/utils/app_router.dart
4. Ajouter confirmReceived(orderId) dans lib/providers/orders_provider.dart
5. Backend PUT /api/orders/:id/confirm-received dans ../djassa-backend/server.js (buyer only, notify seller fcmToken)
6. Ajouter bouton "Mes commandes" dans lib/screens/profile_screen.dart
7. `flutter pub get` + test
