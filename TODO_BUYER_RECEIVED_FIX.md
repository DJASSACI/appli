# Plan de correction : Bouton "Colis Reçu" chez l'acheteur

## Problèmes identifiés après analyse du code

### 1. Route backend manquante
- **Fichier** : `../djassa-backend/server.js`
- **Problème** : La route `PUT /api/orders/:id/received` est appelée par le frontend (`my_orders_screen.dart` ligne 24 et `orders_provider.dart`) mais **n'existe pas** dans le backend.
- **Impact** : L'acheteur ne peut jamais finaliser la réception du colis. Le bouton "Colis Reçu" est visible mais ne fonctionne pas.

### 2. Pas de rafraîchissement automatique côté acheteur
- **Fichier** : `lib/screens/my_orders_screen.dart`
- **Problème** : L'acheteur doit manuellement quitter et revenir sur l'écran pour voir le bouton "Colis Reçu" apparaître après l'action du vendeur.
- **Impact** : Mauvaise UX, l'acheteur ne sait pas que la livraison est confirmée.

### 3. Écran de détail incomplet
- **Fichier** : `lib/screens/order_detail_screen.dart`
- **Problème** : L'écran de détail de commande n'affiche pas le bouton "Colis Reçu" même quand le statut est `livraison_confirmee`.
- **Impact** : L'acheteur ne peut pas confirmer la réception depuis le détail.

---

## Plan de correction détaillé

### Étape 1 : Ajouter la route backend `/api/orders/:id/received`
**Fichier** : `../djassa-backend/server.js`
- Ajouter une route `PUT /api/orders/:id/received`
- Vérifier que l'utilisateur authentifié est bien l'acheteur (`utilisateurId === req.user.id`)
- Vérifier que le statut actuel est `livraison_confirmee`
- Changer le statut à `recu` (ou `terminee`)
- Sauvegarder dans `orders.json`
- Retourner la commande mise à jour

### Étape 2 : Ajouter le bouton "Colis Reçu" dans l'écran de détail
**Fichier** : `lib/screens/order_detail_screen.dart`
- Ajouter un bouton conditionnel en bas de l'écran si `order.statut == 'livraison_confirmee'`
- Appeler `ApiService().put('/api/orders/${order.id}/received')` puis rafraîchir

### Étape 3 : Ajouter le pull-to-refresh dans Mes Commandes (acheteur)
**Fichier** : `lib/screens/my_orders_screen.dart`
- Envelopper la `ListView` dans un `RefreshIndicator`
- Permettre à l'acheteur de tirer vers le bas pour rafraîchir et voir le nouveau statut

### Étape 4 : (Optionnel) Rafraîchissement périodique
**Fichier** : `lib/screens/my_orders_screen.dart`
- Ajouter un `Timer.periodic` dans `initState` pour appeler `fetchMyOrders()` toutes les 30 secondes
- Annuler le timer dans `dispose()`

---

## Fichiers à modifier
1. `../djassa-backend/server.js` — Ajout route `PUT /api/orders/:id/received`
2. `lib/screens/order_detail_screen.dart` — Ajout bouton "Colis Reçu"
3. `lib/screens/my_orders_screen.dart` — Ajout `RefreshIndicator` + timer optionnel

## Dépendances
- Aucune nouvelle dépendance requise

## Tests suggérés
1. Vendeur clique "Confirmer livraison" → statut passe à `livraison_confirmee`
2. Acheteur rafraîchit "Mes commandes" → bouton "Colis Reçu" apparaît
3. Acheteur clique "Colis Reçu" → statut passe à `recu`, message de succès

