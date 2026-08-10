import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduit les [AuthException] Supabase en messages UI compréhensibles.
///
/// Évite le filet trop large « message contient password → Mot de passe invalide »
/// qui masquait `weak_password`, `same_password`, politiques Dashboard, etc.
abstract final class AuthErrorMapper {
  static String map(AuthException error) {
    final code = error.code?.toLowerCase();
    final message = error.message.trim();
    final lower = message.toLowerCase();

    if (error is AuthWeakPasswordException || code == 'weak_password') {
      return mapWeakPassword(error);
    }

    if (code == 'same_password' || lower.contains('same password')) {
      return 'Choisissez un mot de passe différent de l\'ancien.';
    }

    if (code == 'reauthentication_needed' ||
        lower.contains('reauthentication')) {
      return 'La session de réinitialisation a expiré. '
          'Demandez un nouveau lien.';
    }

    if (code == 'session_not_found' ||
        code == 'session_expired' ||
        code == 'session_missing' ||
        error is AuthSessionMissingException ||
        lower.contains('auth session missing') ||
        lower.contains('session missing')) {
      return 'La session de réinitialisation a expiré. '
          'Demandez un nouveau lien.';
    }

    if (lower.contains('current password')) {
      return 'Changement de mot de passe refusé pour cette session. '
          'Demandez un nouveau lien de réinitialisation.';
    }

    if (lower.contains('invalid login credentials')) {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (lower.contains('user already registered') ||
        code == 'user_already_exists' ||
        code == 'email_exists') {
      return 'Un compte existe déjà avec cet e-mail.';
    }
    if (lower.contains('email not confirmed') || code == 'email_not_confirmed') {
      return 'Confirmez votre e-mail avant de vous connecter. '
          'Vérifiez votre boîte de réception (et les indésirables).';
    }
    if (lower.contains('provider is not enabled') ||
        code == 'provider_disabled' ||
        code == 'email_provider_disabled') {
      return 'Ce mode de connexion n\'est pas encore activé.';
    }

    // Politique mot de passe (longueur / caractères) renvoyée en clair par Auth.
    if (_looksLikePasswordPolicyMessage(lower)) {
      return 'Mot de passe refusé par la politique Auth : $message';
    }

    if (lower.contains('password')) {
      return 'Mot de passe refusé : $message';
    }

    if (message.isNotEmpty) {
      return 'Authentification impossible : $message';
    }
    return 'Authentification impossible. Réessayez.';
  }

  /// Messages dédiés à [AuthWeakPasswordException] / code `weak_password`.
  static String mapWeakPassword(AuthException error) {
    final reasons = error is AuthWeakPasswordException
        ? error.reasons
        : const <String>[];
    if (reasons.isEmpty) {
      final fallback = error.message.trim();
      if (fallback.isNotEmpty) {
        return 'Mot de passe trop faible : $fallback';
      }
      return 'Mot de passe trop faible selon la politique du projet '
          '(Authentication → Providers → Email).';
    }

    final parts = <String>[];
    for (final reason in reasons) {
      switch (reason.toLowerCase()) {
        case 'length':
          parts.add(
            'trop court (Minimum password length dans Auth → Email)',
          );
        case 'characters':
          parts.add(
            'types de caractères manquants (Password Requirements)',
          );
        case 'pwned':
          parts.add(
            'compromis / trop courant (Leaked password protection)',
          );
        default:
          parts.add(reason);
      }
    }
    return 'Mot de passe trop faible : ${parts.join(' ; ')}.';
  }

  static bool _looksLikePasswordPolicyMessage(String lower) {
    if (!lower.contains('password')) return false;
    return lower.contains('at least') ||
        lower.contains('character') ||
        lower.contains('digits') ||
        lower.contains('symbols') ||
        lower.contains('uppercase') ||
        lower.contains('lowercase') ||
        lower.contains('weak');
  }
}
