import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/auth_action_result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_credentials_validator.dart';

/// Authentification Supabase avec repli local si le backend est indisponible.
class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository({
    AtlasEnv? env,
    GoTrueClient? Function()? authProvider,
  })  : _env = env ?? AtlasEnv.fromCompileTime(),
        _authProvider = authProvider ?? _defaultAuthProvider,
        super.base();

  final AtlasEnv _env;
  final GoTrueClient? Function()? _authProvider;

  AuthSession _session = const AuthSession.unavailable();
  bool _isLoaded = false;
  StreamSubscription<AuthState>? _authSubscription;

  static GoTrueClient? _defaultAuthProvider() {
    return SupabaseBootstrap.clientOrNull()?.auth;
  }

  @override
  AuthSession get session => _session;

  @override
  bool get isLoaded => _isLoaded;

  GoTrueClient? _auth() => _authProvider?.call();

  @override
  Future<void> load() async {
    _refreshSession();
    _isLoaded = true;
    notifyListeners();

    final auth = _auth();
    if (auth == null) return;

    await _authSubscription?.cancel();
    _authSubscription = auth.onAuthStateChange.listen((_) {
      _refreshSession();
      notifyListeners();
    });
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
      return AuthActionResult.success();
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
  Future<AuthActionResult> signOut() async {
    final auth = _auth();
    if (!_isBackendReady || auth == null) {
      return AuthActionResult.backendUnavailable();
    }

    try {
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
      _session = const AuthSession(
        kind: AuthSessionKind.anonymous,
      );
      return;
    }

    if (user.isAnonymous) {
      _session = AuthSession(
        kind: AuthSessionKind.anonymous,
        userId: user.id,
      );
      return;
    }

    _session = AuthSession(
      kind: AuthSessionKind.signedIn,
      userId: user.id,
      email: user.email,
    );
  }

  static String _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (message.contains('user already registered')) {
      return 'Un compte existe déjà avec cet e-mail.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirmez votre e-mail avant de vous connecter.';
    }
    if (message.contains('password')) {
      return 'Mot de passe invalide.';
    }
    return 'Authentification impossible. Réessayez.';
  }
}
