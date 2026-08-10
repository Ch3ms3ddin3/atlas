import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import 'atlas_auth_redirect.dart';
import '../domain/auth_action_result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_credentials_validator.dart';
import 'auth_error_mapper.dart';

/// Authentification Supabase — e-mail, OAuth, reset, suppression.
///
/// Aucun mot de passe n'est stocké localement ; la session est gérée par le SDK.
class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository({
    AtlasEnv? env,
    GoTrueClient? Function()? authProvider,
    SupabaseClient? Function()? clientProvider,
  })  : _env = env ?? AtlasEnv.fromCompileTime(),
        _authProvider = authProvider ?? _defaultAuthProvider,
        _clientProvider = clientProvider ?? _defaultClientProvider,
        super.base();

  final AtlasEnv _env;
  final GoTrueClient? Function()? _authProvider;
  final SupabaseClient? Function()? _clientProvider;

  AuthSession _session = const AuthSession.unavailable();
  bool _isLoaded = false;
  bool _passwordRecoveryPending = false;
  StreamSubscription<AuthState>? _authSubscription;

  static GoTrueClient? _defaultAuthProvider() {
    return SupabaseBootstrap.clientOrNull()?.auth;
  }

  static SupabaseClient? _defaultClientProvider() {
    return SupabaseBootstrap.clientOrNull();
  }

  @override
  AuthSession get session => _session;

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isPasswordRecoveryPending => _passwordRecoveryPending;

  GoTrueClient? _auth() => _authProvider?.call();

  SupabaseClient? _client() => _clientProvider?.call();

  @override
  Future<void> load() async {
    _refreshSession();
    _isLoaded = true;
    notifyListeners();

    final auth = _auth();
    if (auth == null) return;

    await _authSubscription?.cancel();
    _authSubscription = auth.onAuthStateChange.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(AuthState data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _passwordRecoveryPending = true;
    } else if (data.event == AuthChangeEvent.signedOut) {
      _passwordRecoveryPending = false;
    }
    _refreshSession();
    notifyListeners();
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async {
    final validationError = AuthCredentialsValidator.validateSignIn(
      email: email,
      password: password,
    );
    if (validationError != null) {
      return AuthActionResult.failure(validationError);
    }

    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }

    final sanitizedEmail = AuthCredentialsValidator.sanitizeEmail(email);

    try {
      final currentUser = auth.currentUser;
      if (currentUser?.isAnonymous ?? false) {
        await auth.updateUser(
          UserAttributes(
            email: sanitizedEmail,
            password: password,
          ),
        );
      } else if (currentUser == null) {
        await auth.signUp(
          email: sanitizedEmail,
          password: password,
        );
      } else {
        return AuthActionResult.failure('Vous êtes déjà connecté.');
      }

      _refreshSession();
      notifyListeners();
      // updateUser(email) déclenche toujours une confirmation e-mail côté Auth.
      return AuthActionResult.success(requiresEmailConfirmation: true);
    } on AuthException catch (error) {
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Impossible de créer le compte. Réessayez plus tard.',
      );
    }
  }

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    final validationError = AuthCredentialsValidator.validateSignIn(
      email: email,
      password: password,
    );
    if (validationError != null) {
      return AuthActionResult.failure(validationError);
    }

    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }

    final sanitizedEmail = AuthCredentialsValidator.sanitizeEmail(email);

    try {
      await auth.signInWithPassword(
        email: sanitizedEmail,
        password: password,
      );
      _refreshSession();
      notifyListeners();
      return AuthActionResult.success();
    } on AuthException catch (error) {
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Connexion impossible. Réessayez plus tard.',
      );
    }
  }

  @override
  Future<AuthActionResult> signInWithApple() {
    return _signInWithOAuth(OAuthProvider.apple, AuthProviderKind.apple);
  }

  @override
  Future<AuthActionResult> signInWithGoogle() {
    return _signInWithOAuth(OAuthProvider.google, AuthProviderKind.google);
  }

  Future<AuthActionResult> _signInWithOAuth(
    OAuthProvider provider,
    AuthProviderKind kind,
  ) async {
    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }

    try {
      final launched = await auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : AtlasAuthRedirect.url,
      );
      if (!launched) {
        return AuthActionResult.failure(
          'Connexion ${kind.label} indisponible pour le moment.',
        );
      }
      return AuthActionResult.success();
    } on AuthException catch (error) {
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Connexion ${kind.label} impossible. Réessayez plus tard.',
      );
    }
  }

  @override
  Future<AuthActionResult> resetPassword({required String email}) async {
    final sanitized = AuthCredentialsValidator.sanitizeEmail(email);
    if (sanitized.isEmpty || !sanitized.contains('@')) {
      return AuthActionResult.failure('Saisissez un e-mail valide.');
    }

    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }

    try {
      // Ne pas remplacer par updateUser — recovery uniquement.
      // redirectTo doit être allow-listé côté Dashboard (sinon → Site URL /
      // localhost dans l'e-mail et Safari au lieu d'Atlas).
      if (kDebugMode) {
        debugPrint(
          '[Atlas] resetPasswordForEmail redirectTo=${AtlasAuthRedirect.url}',
        );
      }
      await auth.resetPasswordForEmail(
        sanitized,
        redirectTo: kIsWeb ? null : AtlasAuthRedirect.url,
      );
      // Message anti-énumération côté UI ; succès même si le compte n'existe pas.
      return AuthActionResult.success();
    } on AuthException catch (error) {
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Impossible d\'envoyer le lien de réinitialisation.',
      );
    }
  }

  @override
  Future<AuthActionResult> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final validationError = AuthCredentialsValidator.validatePasswordUpdate(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (validationError != null) {
      return AuthActionResult.failure(validationError);
    }

    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }
    if (!_passwordRecoveryPending) {
      return AuthActionResult.failure(
        'Ouvrez le lien de réinitialisation reçu par e-mail pour continuer.',
      );
    }

    // updateUser(password) exige la session recovery encore authentifiée
    // (pas resetPasswordForEmail, pas une session anonyme).
    final user = auth.currentUser;
    final session = auth.currentSession;
    if (session == null || user == null || user.isAnonymous) {
      if (kDebugMode) {
        debugPrint(
          '[Atlas] recovery updatePassword: session invalide '
          '(session=${session != null}, user=${user?.id}, '
          'anonymous=${user?.isAnonymous})',
        );
      }
      _passwordRecoveryPending = false;
      notifyListeners();
      return AuthActionResult.failure(
        'La session de réinitialisation a expiré. '
        'Demandez un nouveau lien.',
      );
    }

    try {
      await auth.updateUser(UserAttributes(password: newPassword));
      _passwordRecoveryPending = false;
      // Quitte la session recovery : l'utilisateur se reconnecte ensuite.
      await auth.signOut();
      await auth.signInAnonymously();
      _refreshSession();
      notifyListeners();
      return AuthActionResult.success();
    } on AuthException catch (error) {
      if (kDebugMode) {
        final reasons = error is AuthWeakPasswordException
            ? error.reasons.join(',')
            : '';
        debugPrint(
          '[Atlas] recovery updatePassword failed: '
          'code=${error.code} message=${error.message}'
          '${reasons.isEmpty ? '' : ' reasons=$reasons'}',
        );
      }
      // Pending conservé : l'utilisateur peut réessayer sans nouveau lien.
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Impossible de mettre à jour le mot de passe. Réessayez.',
      );
    }
  }

  @override
  Future<AuthActionResult> cancelPasswordRecovery() async {
    if (!_passwordRecoveryPending) {
      return AuthActionResult.success();
    }
    _passwordRecoveryPending = false;
    final result = await signOut();
    notifyListeners();
    return result;
  }

  @override
  Future<AuthActionResult> signOut() async {
    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }

    try {
      _passwordRecoveryPending = false;
      await auth.signOut();
      await auth.signInAnonymously();
      _refreshSession();
      notifyListeners();
      return AuthActionResult.success();
    } on AuthException catch (error) {
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Déconnexion impossible. Réessayez plus tard.',
      );
    }
  }

  @override
  Future<AuthActionResult> deleteAccount() async {
    final client = _client();
    final auth = _auth();
    if (!_isBackendReady || client == null || auth == null) {
      return AuthActionResult.backendUnavailable();
    }
    if (!_session.isSignedIn) {
      return AuthActionResult.failure(
        'Connectez-vous pour supprimer votre compte.',
      );
    }

    try {
      await client.rpc('delete_own_account');
      await auth.signInAnonymously();
      _refreshSession();
      notifyListeners();
      return AuthActionResult.success();
    } on AuthException catch (error) {
      return AuthActionResult.failure(_mapAuthError(error));
    } catch (_) {
      return AuthActionResult.failure(
        'Suppression impossible. Réessayez plus tard.',
      );
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
    super.dispose();
  }

  bool get _isBackendReady =>
      _env.isConfigured && SupabaseBootstrap.isInitialized;

  void _refreshSession() {
    if (!_isBackendReady) {
      _session = const AuthSession.unavailable();
      return;
    }

    final auth = _auth();
    final user = auth?.currentUser;
    if (user == null) {
      _session = const AuthSession(kind: AuthSessionKind.anonymous);
      return;
    }

    if (user.isAnonymous) {
      _session = AuthSession(
        kind: AuthSessionKind.anonymous,
        userId: user.id,
      );
      return;
    }

    final providers = <AuthProviderKind>{};
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      final mapped = AuthProviderKindLabels.fromSupabaseId(identity.provider);
      if (mapped != null) providers.add(mapped);
    }
    if (user.email != null && user.email!.isNotEmpty) {
      providers.add(AuthProviderKind.email);
    }

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final displayName = (meta['full_name'] ?? meta['name'] ?? meta['display_name'])
        ?.toString();
    final avatarUrl = (meta['avatar_url'] ?? meta['picture'])?.toString();

    _session = AuthSession(
      kind: AuthSessionKind.signedIn,
      userId: user.id,
      email: user.email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      providers: providers.toList(growable: false),
    );
  }

  static String _mapAuthError(AuthException error) {
    return AuthErrorMapper.map(error);
  }
}
