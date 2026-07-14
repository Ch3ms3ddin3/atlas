/// Validation applicative des identifiants.
abstract final class AuthCredentialsValidator {
  static const minPasswordLength = 6;
  static const maxPasswordLength = 72;

  static String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (password.length < minPasswordLength) {
      return 'Le mot de passe doit contenir au moins '
          '$minPasswordLength caractères.';
    }
    if (password.length > maxPasswordLength) {
      return 'Le mot de passe est trop long.';
    }
    return null;
  }

  static String? validateSignUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final emailError = validateEmail(email);
    if (emailError != null) return emailError;

    final passwordError = validatePassword(password);
    if (passwordError != null) return passwordError;

    if (password != confirmPassword) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  static String? validateSignIn({
    required String email,
    required String password,
  }) {
    final emailError = validateEmail(email);
    if (emailError != null) return emailError;
    return validatePassword(password);
  }

  static String sanitizeEmail(String email) => email.trim().toLowerCase();
}
