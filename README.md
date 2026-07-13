# Atlas

Compagnon numérique pour vivre, voyager et s'installer au Maroc.

## Getting started

```bash
flutter pub get
flutter run
```

Sans configuration Supabase, l'application fonctionne entièrement avec les catalogues locaux et les APIs publiques existantes.

## Backend (Supabase)

Voir [docs/BACKEND.md](docs/BACKEND.md) pour l'architecture, le schéma prévu et la feuille de route.

### Développement local avec Supabase

```bash
cp .env.development.example .env.development
# Renseigner SUPABASE_URL et SUPABASE_ANON_KEY (clé anon uniquement)

flutter run --dart-define-from-file=.env.development
```

Environnements supportés : `development`, `staging`, `production` (via `ATLAS_ENV`).

## Tests

```bash
flutter analyze
flutter test
```
