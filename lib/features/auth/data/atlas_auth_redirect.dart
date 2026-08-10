/// Deep-link OAuth / reset password — aligné avec `ios/Runner/Info.plist`
/// et `android/app/src/main/AndroidManifest.xml`.
///
/// **Critique (iPhone physique):** ces URLs doivent être enregistrées
/// exactement dans Supabase → Authentication → URL Configuration.
/// Sinon Auth ignore `redirectTo` et retombe sur **Site URL**
/// (souvent `http://localhost:3000`) → Safari, pas Atlas.
///
/// Voir `docs/IOS_APPLE_PORTAL_SETUP.md` § Password recovery.
abstract final class AtlasAuthRedirect {
  static const scheme = 'io.supabase.atlas';
  static const host = 'login-callback';

  /// URL canonique passée à `signInWithOAuth` / `resetPasswordForEmail`.
  /// Format officiel Supabase Flutter : `[scheme]://[host]` (sans slash final).
  static const url = '$scheme://$host';

  /// Variantes à ajouter dans **Additional Redirect URLs** (correspondance exacte).
  static const allowedRedirectUrls = <String>[
    url,
    '$url/',
  ];
}
