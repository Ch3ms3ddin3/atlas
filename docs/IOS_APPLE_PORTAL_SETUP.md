# Atlas iOS — Configuration manuelle (Apple / Supabase / Google)

Ce document liste ce qui **ne peut pas** être finalisé uniquement dans le dépôt Git.  
L’app est préparée côté code (`app.atlas.maroc`, entitlements, deep links, permissions).

## Déjà fait dans le repo

| Élément | Valeur / fichier |
|---------|------------------|
| Bundle ID | `app.atlas.maroc` |
| Signing style | Automatic (Team **non** hardcodé — choisir dans Xcode) |
| Entitlements Sign in with Apple | `ios/Runner/Runner.entitlements` |
| URL scheme OAuth | `io.supabase.atlas` → `ios/Runner/Info.plist` |
| Redirect Dart | `AtlasAuthRedirect.url` = `io.supabase.atlas://login-callback/` |
| Deep links Flutter | `FlutterDeepLinkingEnabled` + `detectSessionInUri: true` |
| Location | `NSLocationWhenInUseUsageDescription` |
| Calendar (écriture) | `NSCalendarsUsageDescription` + `NSCalendarsWriteOnlyAccessUsageDescription` |
| Photos / caméra | **Non demandés** (capture feedback via RepaintBoundary) |
| Maps natives Google | **Non utilisées** (`flutter_map` + OSM) |
| Google Sign-In SDK natif | **Non utilisé** — OAuth navigateur via Supabase |

## Apple Developer Portal (obligatoire pour device / TestFlight)

1. **App ID** `app.atlas.maroc`
   - Activer **Sign In with Apple**
   - (Optionnel plus tard) Push Notifications si APNs distant — aujourd’hui Atlas utilise des notifications **locales**
2. **Certificates / Profiles**
   - Avec Automatic Signing, Xcode crée le profil Development pour votre Team
3. **Devices**
   - Enregistrer l’UDID de l’iPhone de test (Development)
4. **Sign in with Apple — Services ID** (si flux OAuth web / Supabase Apple provider)
   - Créer un Services ID lié au Bundle ID
   - Domaines + Return URLs demandés par Supabase (souvent `https://<project-ref>.supabase.co/auth/v1/callback`)
5. **Keys**
   - Clé Sign in with Apple (.p8) + Key ID + Team ID → à coller dans Supabase → Auth → Apple

> Le Team ID reste dans Xcode / le portail — **jamais** commit dans `project.pbxproj`.

## Supabase Dashboard (Auth)

Dans **Authentication → URL Configuration** :

- Ajouter aux **Additional Redirect URLs** (exact) :
  ```
  io.supabase.atlas://login-callback/
  ```
- Vérifier aussi Site URL (web) si vous testez le web en parallèle.

Dans **Authentication → Providers** :

- **Anonymous** : activé (mode local / anonyme Atlas)
- **Email** : activé (signup / login / reset)
- **Apple** : activé + Services ID / Key / Team configurés
- **Google** : activé + Client ID / Secret Google Cloud

> Si `io.supabase.atlas://login-callback/` n’est **pas** encore enregistré côté projet distant, l’app compile quand même ; OAuth / reset password échoueront jusqu’à l’ajout de cette URL. **Ne bloque pas** l’implémentation locale.

## Google Cloud (OAuth navigateur via Supabase)

Atlas n’embarque **pas** `google_sign_in` ni `GoogleService-Info.plist`.

Configurer plutôt :

1. OAuth Client **Web** (souvent celui utilisé par Supabase) — Client ID + Secret dans Supabase → Google provider
2. Authorized redirect URI Google → callback Supabase  
   `https://<project-ref>.supabase.co/auth/v1/callback`
3. Pas de client iOS Google natif **requis** pour le flux actuel `signInWithOAuth(OAuthProvider.google)`

Vérification code : `SupabaseAuthRepository.signInWithGoogle()` → `redirectTo: AtlasAuthRedirect.url`.

## Xcode (une fois par machine / Team)

1. Ouvrir `ios/Runner.xcworkspace` (ou laisser Flutter générer après le premier build)
2. Target **Runner** → **Signing & Capabilities**
   - Team = votre équipe
   - Automatically manage signing = ON
   - Capability **Sign In with Apple** déjà via entitlements (re-sync si besoin)
3. Brancher l’iPhone → Run

## Permissions volontairement absentes

Ne pas ajouter sans besoin produit :

- `NSPhotoLibrary*` / `NSCamera*` / `NSMicrophone*`
- `NSLocationAlways*`
- `NSContacts*`
- `UIBackgroundModes` location

## Prérequis machine (obligatoires pour build iOS)

Sur la machine de build / de test iPhone :

1. **Xcode complet** (App Store), pas seulement Command Line Tools
2. ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. **CocoaPods** (`sudo gem install cocoapods` ou Homebrew)
4. Compte Apple Developer + Team sélectionné dans Xcode

Sans Xcode.app, `flutter build ios` échoue avec *Application not configured for iOS*.

## Commandes de vérification (Mac avec Xcode)

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ios --debug
flutter build ios --release --no-codesign
```

Device :

```bash
flutter run -d <iphone-id> --dart-define-from-file=.env.development
```

## Checklist manuelle

Voir [IOS_DEVICE_CHECKLIST.md](./IOS_DEVICE_CHECKLIST.md).
