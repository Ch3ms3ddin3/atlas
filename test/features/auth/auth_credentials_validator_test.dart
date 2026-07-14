import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/auth/data/auth_credentials_validator.dart';

void main() {
  group('AuthCredentialsValidator', () {
    test('rejette un e-mail vide', () {
      expect(AuthCredentialsValidator.validateEmail(''), isNotNull);
    });

    test('accepte un e-mail valide', () {
      expect(
        AuthCredentialsValidator.validateEmail('salma@exemple.com'),
        isNull,
      );
    });

    test('rejette un mot de passe trop court', () {
      expect(AuthCredentialsValidator.validatePassword('123'), isNotNull);
    });

    test('valide une inscription avec confirmation', () {
      expect(
        AuthCredentialsValidator.validateSignUp(
          email: 'salma@exemple.com',
          password: 'secret12',
          confirmPassword: 'secret12',
        ),
        isNull,
      );
    });

    test('rejette une confirmation différente', () {
      expect(
        AuthCredentialsValidator.validateSignUp(
          email: 'salma@exemple.com',
          password: 'secret12',
          confirmPassword: 'autre',
        ),
        isNotNull,
      );
    });

    test('normalise l e-mail', () {
      expect(
        AuthCredentialsValidator.sanitizeEmail('  Salma@Exemple.COM '),
        'salma@exemple.com',
      );
    });
  });
}
