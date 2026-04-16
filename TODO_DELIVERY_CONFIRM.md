# TODO: Livraison Confirmée Button

1. ✅ [DONE] Create TODO.md with plan
2. ✅ [DONE] Added backend endpoint PUT /api/orders/:id/confirm-delivery in ../djassa-backend/server.js (seller auth, set status='livraison_confirmee', seller owns order)
3. ✅ [DONE] Added confirmDelivery(orderId) method in lib/providers/orders_provider.dart
4. ✅ [DONE] Added "Livraison Confirmée" button in lib/screens/my_seller_orders_screen.dart Row (keep existing Livrer/Yango untouched, new button conditional if(order.statut == 'livree'), call confirmDelivery)
5. ✅ [DONE] "Livrer" now auto-opens Yango avec coords livraison (nomLivraison + quartier + villeCommune) si disponibles
6. ✅ [DONE] Tâche complète!
