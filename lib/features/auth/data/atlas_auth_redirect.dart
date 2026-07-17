/// Deep-link OAuth / reset password — aligné avec `ios/Runner/Info.plist`
/// et `android/app/src/main/AndroidManifest.xml`.
///
/// Doit aussi être listé dans Supabase → Authentication → URL Configuration
/// → Additional Redirect URLs.
abstract final class AtlasAuthRedirect {
  static const scheme = 'io.supabase.atlas';
  static const host = 'login-callback';

  /// URL complète passée à `signInWithOAuth` / `resetPasswordForEmail`.
  static const url = '$scheme://$host/';
}
