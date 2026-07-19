# Plan: Rendre /api/auth/me non-bloquant

## Objectif
Faire en sorte que la session fonctionne uniquement avec le local storage et que /api/auth/me soit optionnel en arrière-plan.

## Analyse du Code Existant

### Fichiers Examinés:
1. **lib/main.dart** - ✅ Restaure la session avant le démarrage avec `initializeSession()`
2. **lib/screens/splash_screen.dart** - ✅ Utilise `loadUserFromStorage()` et navigue immédiatement 
3. **lib/providers/auth_provider.dart** - Contient `loadCurrentUser()`, `loadUserFromStorage()`, `refreshUserInBackground()`
4. **lib/services/auth_service.dart** - Contient `getCurrentUser()` qui appelle `/api/auth/me`

### État Actuel:
- Le flux principal utilise déjà `loadUserFromStorage()` qui est non-bloquant ✅
- `refreshUserInBackground()` fait un appel API qui pourrait être long ⚠️

## Modifications à Apporter

### 1. lib/providers/auth_provider.dart
**Modifier `refreshUserInBackground()` pour ajouter un timeout**
- Ajouter un timeout de 3 secondes max
- Ne JAMAIS bloquer l'application

### 2. lib/screens/splash_screen.dart
**Ajouter un timeout explicite à `_syncUserInBackground()`**
- Timeout de 5 secondes pour la synchronisation en arrière-plan
- S'assurer que la navigation n'est jamais retardée

## Résultat Attendu
- ✅ L'app démarre instantanément avec le local storage
- ✅ /api/auth/me devient optionnel pour sync en arrière-plan
- ✅ L'utilisateur est considéré connecté dès que les données locales sont restaurées
- ✅ Pas de blocage, pas de redirects vers login en cas d'erreur/timeout

## Fichiers à Modifier
1. lib/providers/auth_provider.dart
2. lib/screens/splash_screen.dart

## Aucune Modification Requise
- lib/main.dart (déjà correct)
- lib/services/auth_service.dart
- lib/utils/app_router.dart
