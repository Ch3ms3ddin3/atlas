import 'package:flutter/foundation.dart';

import 'auth_action_result.dart';
import 'auth_session.dart';

/// Contrat d'authentification — indépendant de Supabase.
abstract class AuthRepository extends ChangeNotifier {
  AuthRepository.base();

  AuthSession get session;

  bool get isLoaded;

  /// `true` après un deep link / événement `PASSWORD_RECOVERY` Supabase.
  bool get isPasswordRecoveryPending;

  Future<void> load();

  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  });

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  });

  Future<AuthActionResult> signInWithApple();

  Future<AuthActionResult> signInWithGoogle();

  Future<AuthActionResult> resetPassword({required String email});

  /// Définit un nouveau mot de passe pendant une session de recovery.
  Future<AuthActionResult> updatePassword({
    required String newPassword,
    required String confirmPassword,
  });

  /// Abandonne le flux recovery (nouvelle session anonyme).
  Future<AuthActionResult> cancelPasswordRecovery();

  Future<AuthActionResult> signOut();

  Future<AuthActionResult> deleteAccount();
}
