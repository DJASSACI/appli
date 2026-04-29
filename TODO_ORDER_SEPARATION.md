# TODO - Séparation des commandes Vendeur/Acheteur

## Étape 1: Backend - Création de commandes par vendeur (server.js)
- [ ] Modifier `POST /api/orders` pour grouper les articles par vendeur et créer une commande par vendeur
- [ ] Corriger `GET /api/orders/seller/:sellerId` avec normalisation des types int/string
- [ ] Corriger `GET /api/orders/my` avec comparaison numérique stricte
- [ ] Restreindre `GET /api/orders` à admin uniquement
- [ ] Corriger `PUT /api/orders/:id/deliver` pour vérifier ownership vendeur
- [ ] Corriger `PUT /api/orders/:id/confirm-delivery` pour vérifier ownership vendeur

## Étape 2: Frontend - Écran vendeur (my_seller_orders_screen.dart)
- [ ] Filtrer les articles pour n'afficher que ceux du vendeur connecté
- [ ] Calculer et afficher le sous-total pour le vendeur (pas le total global)
- [ ] Masquer les boutons d'action si le vendeur n'a pas d'articles dans la commande

## Étape 3: Frontend - Provider (orders_provider.dart)
- [ ] Vérifier que `fetchSellerOrders` utilise le bon endpoint
- [ ] Vérifier que `fetchMyOrders` fonctionne correctement

## Étape 4: Test et vérification
- [ ] Vérifier qu'un vendeur ne voit que ses commandes
- [ ] Vérifier qu'un acheteur ne voit que ses commandes
- [ ] Vérifier que les anciennes commandes legacy sont encore supportées

