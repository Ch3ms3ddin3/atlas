import 'package:flutter/foundation.dart';

import 'auth_action_result.dart';
import 'auth_session.dart';

/// Contrat d'authentification — indépendant de Supabase.
abstract class AuthRepository extends ChangeNotifier {
  AuthRepository.base();

  AuthSession get session;

  bool get isLoaded;

  Future<void> load();

  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  });

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  });

  Future<AuthActionResult> signOut();
}
