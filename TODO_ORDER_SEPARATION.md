# Separate Buyer/Seller Orders - Plan

## Information Gathered:
- **Backend** (`server.js`): 
  - ✅ POST /api/orders sets `utilisateurId` (buyer) + `seller` (from product.vendeur)
  - ✅ GET /api/orders/my → filters `o.utilisateurId === req.user.id` (buyer)
  - ✅ GET /api/orders/seller/:sellerId → filters `order.seller === sellerId` OR legacy articles
  - PUT /api/orders/:id/confirm-delivery checks seller owns product in order
- **Frontend**:
  - ✅ `my_orders_screen.dart` calls `fetchMyOrders()` → `/api/orders/my`
  - ✅ `my_seller_orders_screen.dart` calls `fetchSellerOrders()` → `/api/orders/seller/:id`
  - ✅ Model `Order` has `utilisateurId`, `seller`
- **Status**: Already correctly separated! Backend stores `buyerId` (utilisateurId) + `sellerId` (seller)

## No Changes Needed:
```
Buyer (/my_orders_screen): Sees only utilisateurId === my ID ✅
Seller (/my_seller_orders_screen): Sees only seller === my ID ✅
Order Creation: Auto-sets seller from product.vendeur ✅
```

**Test**: 
```
1. User A buys from Seller B → Order has utilisateurId=A, seller=B
2. A sees in my_orders ✅ B sees in my_seller_orders ✅
```

## Followup: Run `node ../djassa-backend/server.js` + `flutter run` to verify separation works perfectly.
