# Atlas iOS — Configuration manuelle (Apple / Supabase / Google)

Ce document liste ce qui **ne peut pas** être finalisé uniquement dans le dépôt Git.  
L’app est préparée côté code (`app.atlas.maroc`, entitlements, deep links, permissions).

## Déjà fait dans le repo

| Élément | Valeur / fichier |
|---------|------------------|
| Bundle ID | `app.atlas.maroc` |
| Signing style | Automatic (Team **non** hardcodé — choisir dans Xcode) |
| Entitlements Sign in with Apple | `ios/Runner/Runner.entitlements` |
| URL scheme OAuth / recovery | `io.supabase.atlas` → `ios/Runner/Info.plist` |
| Redirect Dart | `AtlasAuthRedirect.url` = `io.supabase.atlas://login-callback` |
| Deep links | `FlutterDeepLinkingEnabled=false` + `detectSessionInUri: true` (app_links) |
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

## Supabase Dashboard (Auth) — obligatoire pour recovery iPhone

Ouvrir **Authentication → URL Configuration** :

### Site URL

Pour Atlas (app mobile-first, pas de site web produit) :

```
io.supabase.atlas://login-callback
```

Si **Site URL** reste `http://localhost:3000` (défaut) et que `redirectTo`
n’est pas allow-listé, le lien « Reset password » redirige Safari vers
**localhost** → « Impossible d’ouvrir la page ».

### Additional Redirect URLs

Ajouter **exactement** ces deux lignes (correspondance exacte côté Auth) :

```
io.supabase.atlas://login-callback
io.supabase.atlas://login-callback/
```

Le code envoie `io.supabase.atlas://login-callback` (sans slash final).

### Authentication → Email Templates → Reset password

Le bouton / lien doit utiliser **`{{ .ConfirmationURL }}`** (pas un lien
construit seulement avec `{{ .SiteURL }}`).

Exemple sûr (template par défaut Supabase) :

```html
<h2>Reset Password</h2>
<p>Follow this link to reset the password for your user:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
```

### Providers

- **Anonymous** : activé (mode local / anonyme Atlas)
- **Email** : activé (signup / login / reset)
- **Apple** : activé + Services ID / Key / Team configurés
- **Google** : activé + Client ID / Secret Google Cloud

### Pourquoi Safari ouvre localhost

1. L’e-mail ouvre d’abord `https://<project>.supabase.co/auth/v1/verify?…`
2. Auth redirige ensuite vers `redirect_to`
3. Si `redirect_to` n’est **pas** dans Additional Redirect URLs → Auth utilise
   **Site URL** (souvent `http://localhost:3000`)
4. Safari reste sur localhost ; Atlas ne reçoit jamais le deep link

Après correction Dashboard : un **nouvel** e-mail de reset est requis
(l’ancien lien conserve l’ancien `redirect_to`).

> Sans ces réglages Dashboard, l’app compile et le reset envoie un e-mail,
> mais le deep link iPhone échoue. Ce n’est **pas** contournable depuis le
> dépôt Git seul.

### Authentication → Providers → Email → Password (update après recovery)

Atlas valide localement **≥ 6 caractères**. Si « Enregistrer le mot de passe »
échoue alors que la feuille recovery s’ouvre, vérifier **exactement** ces
réglages Dashboard (ne pas affaiblir le code Atlas pour contourner) :

| Setting | Où | Effet si trop strict |
| --- | --- | --- |
| **Minimum password length** | Auth → Providers → Email | `weak_password` / reason `length` |
| **Password Requirements** (digits / lower / upper / symbols) | idem | `weak_password` / reason `characters` |
| **Leaked password protection** | idem (Pro+) | `weak_password` / reason `pwned` |
| **Secure password change** (reauthentication) | Auth → password security | `reauthentication_needed` si session trop vieille |
| **Require current password when updating** | idem | doit être ignoré pour une vraie session recovery ; sinon demander un **nouveau** lien |

L’écran recovery appelle uniquement `updateUser(password: …)` sur la session
`PASSWORD_RECOVERY` — **pas** `resetPasswordForEmail`.

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
