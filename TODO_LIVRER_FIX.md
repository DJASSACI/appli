# TODO: Correction Bouton Livrer

## Problèmes identifiés
1. Endpoint backend `PUT /api/orders/:id` n'existe pas → le bouton retourne 404
2. `markDelivered()` appelle `fetchOrders()` (toutes commandes) au lieu de `fetchSellerOrders()`
3. Méthode `_markDelivered` morte et imports dupliqués dans `my_seller_orders_screen.dart`

## Plan de correction (minimal, sans casser le code existant)

### Étape 1: Backend
- [x] Ajouter `PUT /api/orders/:id/deliver` dans `../djassa-backend/server.js`
  - Auth vendeur, vérifie statut `payée`, passe à `livree`

### Étape 2: Provider
- [x] Modifier `markDelivered()` dans `lib/providers/orders_provider.dart`
  - Utiliser `/api/orders/$orderId/deliver`
  - Retirer `fetchOrders()` interne (laisser l'UI gérer le refresh)
- [x] Modifier `confirmDelivery()` pour cohérence (même problème de refresh)

### Étape 3: UI Vendeur
- [x] Nettoyer `lib/screens/my_seller_orders_screen.dart`
  - Supprimer méthode `_markDelivered` inutilisée
  - Supprimer imports dupliqués
  - Après clic "Livrer", appeler `fetchSellerOrders()` pour refresh correct
  - Après clic "Confirmer livraison", appeler `fetchSellerOrders()` pour refresh correct

### Étape 5: Filtrage vendeur robuste
- [x] Amélioré `GET /api/orders/seller/:sellerId` dans `../djassa-backend/server.js`
  - Ajout d'un fallback par lookup dans `products.json` pour les anciennes commandes sans `article.seller`
  - Le vendeur voit désormais **uniquement** les commandes liées à ses produits, quelle que soit la version des données

