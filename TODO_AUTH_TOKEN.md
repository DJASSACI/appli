# Fix 401 Unauthorized on "Livrer" - Token Restoration

## Steps:

### 1. ✅ Create TODO_AUTH_TOKEN.md

### 2. [ ] Update lib/screens/splash_screen.dart
   - Call authProvider.loadCurrentUser() in initState
   - Navigate after loaded

### 3. [ ] Update lib/main.dart (if needed)
   - Ensure providers init order correct

### 4. [ ] Verify lib/screens/my_seller_orders_screen.dart
   - OrdersProvider uses shared ApiService instance

### 5. Test
   - Login → restart app → "Livrer" works (200 OK)

### 6. Complete ✅
