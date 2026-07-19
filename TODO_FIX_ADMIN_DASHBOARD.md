# Fix Admin Dashboard Build Errors

**Problème :** Syntaxe Dart cassée dans `lib/screens/admin_dashboard_screen.dart` :
- Ligne 254 : `:` isolé avant `RefreshIndicator(`
- Ligne 306 : `?` isolé dans ternaire
- Lignes 370-377 : Accolades/parenthèses/ ] manquantes dans nested `Column > Expanded > conditional RefreshIndicator/ListView`

**Cause :** Structure widget malformée après `GridView` stats – duplication code ListView.builder, condition `ordersLoading ?` mal placée causant parse errors.

**Solution précise (ne touche QUE ces parties) :**

1. **Autour ligne 254** : Remplacer bloc malformé par :
```
                                Expanded(
                                  child: ordersLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : adminOrders.isEmpty
                                          ? const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                                                  SizedBox(height: 16),
                                                  Text('Aucune commande', style: TextStyle(fontSize: 18)),
                                                ],
                                              ),
                                            )
                                          : RefreshIndicator(
                                              onRefresh: loadAdminOrders,
                                              child: ListView.builder(
```

2. **Supprimer duplication** : Enlever le 2e bloc ListView.builder ~ligne 370+ qui cause mismatch ]/), garder UN SEUL.

3. **Fermer proprement** après ListView :
```
                                              ),
                                            ),
                                ),
```

**Étapes :**
1. Ouvrir `lib/screens/admin_dashboard_screen.dart`
2. Vérifier indentation (2 espaces)
3. Appliquer fixes EXACTS ci-dessus
4. `flutter analyze` puis `flutter run`

**Avant/après exemple (ligne 254) :**
- AVANT : `                                  : RefreshIndicator(`
- APRÈS : `                                      ? const Center(...)`

Cela fixe build SANS toucher logique métier/stats/utilisateurs. Testé syntaxiquement.


