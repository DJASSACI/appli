# Guide Complet: Comment utiliser Firebase dans votre app Flutter Djassaci 🚀

## Introduction
Ce guide explique **comment intégrer Firebase** pour **Authentification** (remplace auth_service.dart) et **Firestore** (remplace backend JSON). Votre app actuelle utilise un backend local Node.js - Firebase le remplacera par cloud.

## Prérequis
- Flutter SDK installé
- Android Studio (pour SHA-1)
- Compte Google/Firebase

## Étape 1: Créer Projet Firebase (5 min)
1. [console.firebase.google.com](https://console.firebase.google.com) → "Nouveau projet" → `djassaci`
2. **Authentication** → Get started → Sign-in method → Enable **Phone** + **Email/Password**
3. **Firestore Database** → Create database → Start in **test mode** → Next → Région `europe-west1`

## Étape 2: Config Android (IMPORTANT)
1. Ouvrir `android/app/build.gradle.kts` → Chercher `applicationId` (ex: `com.example.flutter_application_13`)
2. Obtenir SHA-1:
   ```
   cd android
   gradlew signingReport
   ```
   Copiez **SHA1 Debug** (ex: 12:34:56...)
3. Firebase Console → Project Settings → Add app Android:
   - Package name: votre applicationId
   - SHA certificate fingerprint: votre SHA1
4. **Téléchargez `google-services.json`** → Copiez dans `android/app/google-services.json` (créé dossier si besoin)

## Étape 3: iOS (Optionnel)
1. Firebase → Add iOS app → Bundle ID from ios/Runner.xcodeproj
2. Téléchargez `GoogleService-Info.plist` → Glissez dans ios/Runner/

## Étape 4: Ajouter Dépendances Flutter
Exécutez **dans ordre**:
```
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub get
```

## Étape 5: FlutterFire CLI (Recommandé - Auto-config)
```
# Installer CLI globalement
dart pub global activate flutterfire_cli

# Configurer (connecte Google, sélectionne projet)
flutterfire configure --project=djassaci --platforms=android,ios,web
```
Cela crée `lib/firebase_options.dart` et met à jour natifs.

## Étape 6: Configurer Code (Fichiers à modifier)
### a) lib/main.dart - Initialiser Firebase
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Généré par CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### b) android/build.gradle.kts - Ajouter plugin
```kotlin
// Au début
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false // AJOUTER
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
}
```

### c) android/app/build.gradle.kts - Appliquer plugin + deps
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // AJOUTER EN FIN
}

dependencies {
    // ... existants
    implementation(platform("com.google.firebase:firebase-bom:33.7.0")) // AJOUTER
    implementation("com.google.firebase:firebase-analytics") // OPTION
}
```

### d) auth_service.dart - Migrer vers FirebaseAuth (exemple)
```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print(e);
    }
    return null;
  }

  // Stream pour état auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> logout() async => await _auth.signOut();
}
```

## Étape 7: Tester
```
flutter clean
flutter pub get
flutter run
```

## Dépannage
| Erreur | Solution |
|--------|----------|
| `google-services.json introuvable` | Vérifiez emplacement `android/app/` |
| SHA1 invalide | Re-générer `gradlew signingReport` |
| iOS pods | `cd ios &amp;&amp; pod install` |
| "No Firebase App" | Ajouté `Firebase.initializeApp()` dans main() |
| Phone Auth | Vérifiez "Phone numbers for testing" in Firebase Console |

## Prochaines Étapes Avancées
- **Règles Firestore** sécurisées
- **Upload images** avec Firebase Storage
- **Push notifications** FCM
- Migrer données JSON → Firestore

**Besoin d'aide code spécifique? Demandez-moi d'éditer les fichiers!** ✅

Copiez ce fichier dans votre projet pour référence.

