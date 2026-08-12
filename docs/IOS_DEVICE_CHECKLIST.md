# Atlas — Checklist iPhone (private beta)

Bundle ID: `app.atlas.maroc` · Version: `1.0.0+2` (current in `pubspec.yaml`)  
**Next TestFlight archive build number:** `1.0.0+3` — bump only  
`version: 1.0.0+3` in `pubspec.yaml` (and rebuild) when creating the first  
TestFlight upload. Do not bump during Milestone 2 Phase 1 code work.

Redirect OAuth / recovery: `io.supabase.atlas://login-callback`  
(Must also be allow-listed in Supabase Auth URL Configuration — see `IOS_APPLE_PORTAL_SETUP.md`.)

Install via Xcode / `flutter run` with Automatic Signing (Team choisi dans Xcode).  
Env: `--dart-define-from-file=.env.development` (ou staging/production).

## TestFlight build notes

- Use `.env.staging` or `.env.production` with **real** `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
- Release / staging / production builds **refuse** empty or example placeholders at startup.
- Keep `SHOW_EXPERIMENTAL_SURFACES=false` (hides Assistant + Itinéraires entry points).
- Keep `SHOW_BETA_FEEDBACK=true` so testers can use **Signaler (bêta)**.
- `SENTRY_DSN` remains optional.

## Préparation appareil

- [ ] iPhone physique branché, mode Développeur / confiance OK
- [ ] Team ID sélectionné dans Xcode → Runner → Signing & Capabilities (pas hardcodé dans le repo)
- [ ] Capability **Sign In with Apple** visible sur la target Runner
- [ ] Build Debug installée sans erreur de provisioning

## Onboarding

- [ ] Premier lancement : splash → onboarding → Accueil
- [ ] Dialogue « Bienvenue dans la bêta Atlas » (une fois)
- [ ] Choix ville / profil persistés après kill forcé
- [ ] Relance : onboarding non réaffiché

## Authentification

- [ ] Mode anonyme / local utilisable sans compte
- [ ] Inscription e-mail + mot de passe
- [ ] Connexion e-mail + mot de passe
- [ ] Apple / Google **absents** (`SHOW_SOCIAL_AUTH=false`)
- [ ] Réinitialisation mot de passe :
  - [ ] Dashboard : Site URL + Redirect URLs = `io.supabase.atlas://login-callback` (± `/`)
  - [ ] E-mail reçu : long-press / inspecter le lien → `redirect_to` contient `io.supabase.atlas`, **pas** `localhost`
  - [ ] Tap « Reset password » → Atlas s’ouvre (pas Safari bloqué sur localhost)
  - [ ] Feuille « Nouveau mot de passe » → enregistrement → reconnexion OK
- [ ] Déconnexion → session anonyme sans crash
- [ ] Force-quit puis relance : session conservée

## Accueil

- [ ] Safe area (encoche / Dynamic Island)
- [ ] Météo / prière / change (skeleton → contenu)
- [ ] FAB « Signaler (bêta) » visible (debug **et** profile/release)
- [ ] FAB n’occulte pas le bas de liste
- [ ] Permissions localisation : accepter / refuser (fallback ville)

## Explorer

- [ ] Recherche (expansion) + filtres chips
- [ ] Ouverture fiche lieu + favori
- [ ] Scroll fluide, pas d’overflow

## Carte

- [ ] Tuiles OSM + attribution
- [ ] Sélection marqueur + animation caméra + fiche aperçu
- [ ] Filtres partagés avec Explorer

## Démarches / Prix

- [ ] Listes + détail
- [ ] Scroll position / pas de jump layout

## Profil

- [ ] Édition prénom / ville
- [ ] Section compte + sync status
- [ ] **Pas** d’entrée Assistant / Itinéraires (flag off)
- [ ] Véhicules AT + rappels (permission notifications accepter / refuser)

## Feedback bêta

- [ ] FAB → sheet → envoi avec / sans capture écran
- [ ] Pas de demande d’accès Photos

## Calendrier

- [ ] Ajouter un événement (si proposé) → feuille Calendrier système
- [ ] Refus permission : pas de crash

## Système / accessibilité

- [ ] Réduire les animations (Réglages) : UI utilisable, pas de blocage
- [ ] Haptics ressentis sur actions (pas sur simulateur forcément)
- [ ] Gesture retour iOS sur écrans poussés
- [ ] Sheets modales (auth, feedback, aperçu carte)
- [ ] Passage arrière-plan → premier plan
- [ ] Mode avion / offline : catalogues locaux, pas d’écran blanc

## Perf (observation)

- [ ] Cold start acceptable pour une bêta
- [ ] Première ouverture Carte sans freeze prolongé
- [ ] Pas d’alertes mémoire anormales en navigation onglets

## Build release (hors appareil)

- [ ] `flutter build ios --release --no-codesign` OK sur Mac
- [ ] Avec placeholders staging/production → écran « Build non configurée »
