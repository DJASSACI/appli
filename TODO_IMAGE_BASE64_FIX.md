# Fix Images ne s'affichent pas (!)

## Problème
Produits dans `../djassa-backend/products.json` ont `image: "data:image/jpeg;base64,..."`  
`Image.network()` ne peut pas afficher base64 → montre "!"

## Solution (sans toucher code Flutter)
1. **Ouvrir** `../djassa-backend/products.json`
2. **Trouver** produits avec base64 (id: 1775128528485, 1775130177629, 1775130857580, 1775598649578, 1777397602383)
3. **Remplacer** base64 par:
```
"https://via.placeholder.com/400x400/gray/ffffff?text=Image"
```
   ou URL Firebase Storage valide

## Test nouveau produit
1. App → SellScreen → créer produit avec photo
2. Vérifier console: `✅ [STORAGE] SUCCESS: https://firebasestorage...`
3. Refresh HomeScreen → nouvelle image s'affiche

## Flutter code ✅ OK
- Upload: FirebaseStorage → "products/" ✓
- Save: imageUrl → backend ✓  
- Display: CachedNetworkImage(imageUrl) ✓

**Redémarrer backend** après édition JSON: `cd ../djassa-backend && node server.js`

