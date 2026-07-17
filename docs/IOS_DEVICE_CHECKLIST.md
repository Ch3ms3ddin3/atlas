# Atlas — Checklist iPhone (private beta)

Bundle ID: `app.atlas.maroc` · Version: `1.0.0+2`  
Redirect OAuth: `io.supabase.atlas://login-callback/`

Install via Xcode / `flutter run` with Automatic Signing (Team choisi dans Xcode).  
Env: `--dart-define-from-file=.env.development` (ou staging/production).

## Préparation appareil

- [ ] iPhone physique branché, mode Développeur / confiance OK
- [ ] Team ID sélectionné dans Xcode → Runner → Signing & Capabilities (pas hardcodé dans le repo)
- [ ] Capability **Sign In with Apple** visible sur la target Runner
- [ ] Build Debug installée sans erreur de provisioning

## Onboarding

- [ ] Premier lancement : splash → onboarding → Accueil
- [ ] Choix ville / profil persistés après kill forcé
- [ ] Relance : onboarding non réaffiché

## Authentification

- [ ] Mode anonyme / local utilisable sans compte
- [ ] Inscription e-mail + mot de passe
- [ ] Connexion e-mail + mot de passe
- [ ] Continuer avec Apple (retour app + session active)
- [ ] Continuer avec Google (navigateur / ASWebAuthentication → retour app)
- [ ] Réinitialisation mot de passe (e-mail reçu → lien ouvre Atlas)
- [ ] Déconnexion → session anonyme sans crash
- [ ] Force-quit puis relance : session conservée

## Accueil

- [ ] Safe area (encoche / Dynamic Island)
- [ ] Météo / prière / change (skeleton → contenu)
- [ ] FAB « Signaler » n’occulte pas le bas de liste
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

## Assistant

- [ ] Clavier ne masque pas le champ d’envoi
- [ ] Suggestions / envoi message (quota / offline OK)

## Itinéraires

- [ ] Création trajet (sheet)
- [ ] Détail jours / ajouts

## Profil

- [ ] Édition prénom / ville
- [ ] Section compte + sync status
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
