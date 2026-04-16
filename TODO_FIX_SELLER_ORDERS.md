# Fix Seller Orders Visibility - Products bought by clients not visible in seller's orders

## Goal
Make sure when a client clicks 'Commander'/'Acheter maintenant', the order appears automatically in the correct seller's 'Mes commandes' screen.

## Steps from Analysis

5. [ ] Test: Create product as seller → buy as client → check seller screen
6. [ ] [Optional] Backend: Add /api/orders/seller/my endpoint
7. [ ] Update existing orders.json if needed

## Current Issue
Seller filter: product.vendeur == seller.id fails because articles lack 'vendeur' field.

## Priority
High - Core e-commerce flow broken

