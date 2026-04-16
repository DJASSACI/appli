# ✅ TEST COMMANDES VENDEUR - SUIVEZ CES ÉTAPES

## Backend ✅ FIXÉ & PRÊT (server.js modifié, autorise vendeurs)

## 1. **LANCER BACKEND** (si pas déjà fait)
```
cd "../djassa-backend"
npm start
```
**Attendez "🚀 Djassa CI Backend Server running on port 3000"**

## 2. **TEST avec vos 2 comptes existants :**

### **COMPTE VENDEUR : massa (ID=1774811941531)**
```
Login: 0777380334 | Password: massa bb
```
**Ses produits :** "apache", "le too", "fior"

### **COMPTE CLIENT : mawa (ID=1774815580226)**
```
Login: 0715926401 | Password: mawa bb
```

## 3. **TEST FLUX COMMANDE :**

**CLIENT (mawa) :**
```
1. Login → Home → Cherche "fior" ou "apache"
2. Clique produit → "Acheter maintenant"
3. Remplit TOUS champs :
   - Paiement: Wave/Orange
   - Tel: 0715926401
   - Nom compte: Mawa Test
   - Livraison: Nom/Adresse/Tel/Ville/Quartier
4. "Passer la commande" → ✅ Succès
```

**VENDEUR (massa) :**
```
1. Logout → Login vendeur
2. → MES COMMANDES (my_seller_orders_screen)
3. Clique 🔄 REFRESH ou Pull-to-refresh
4. → Voit commande #ID avec :
   ✅ ID commande, total
   ✅ Acheteur ID, nom, tel paiement
   ✅ Livraison complète
   ✅ Produit "fior" (image/nom/prix/quantité)
   ✅ Boutons Livrer/Yango/Confirmer
```

## 4. **DÉJÀ UNE COMMANDE TEST** (orders.json)
```
#1775591726885 | Client:1774811941531 | "fior" | Total:1050FCFA
```
**Vendeur massa doit la voir maintenant !**

## 5. **VÉRIFICATION TECH** :
```
Navigateur/Postman → http://10.0.2.2:3000/api/health
→ {status: 'ok'} ✅ Backend UP

API Orders → http://10.0.2.2:3000/api/orders (avec token)
→ Toutes commandes ✅
```

## 🚨 **PROBLÈMES POSSIBLES :**
- **"Aucune commande"** → Backend pas lancé OU mauvais produit acheté
- **Erreurs API** → Vérifiez console Flutter (hot reload)
- **Emulator** → baseUrl=10.0.2.2:3000 OK
- **Device physique** → Changez baseUrl=IP_VOTRE_PC:3000

**TESTEZ MAINTENANT & Dites-moi résultat !** 🎯

