import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atlas/features/auth/data/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper', () {
    test('ne masque plus weak_password derrière Mot de passe invalide', () {
      final mapped = AuthErrorMapper.map(
        AuthWeakPasswordException(
          message: 'Password is known to be weak and easy to guess',
          statusCode: '422',
          reasons: const ['pwned'],
        ),
      );

      expect(mapped, isNot(contains('Mot de passe invalide')));
      expect(mapped.toLowerCase(), contains('faible'));
      expect(mapped.toLowerCase(), contains('compromis'));
    });

    test('détaille length et characters pour la politique Dashboard', () {
      final mapped = AuthErrorMapper.mapWeakPassword(
        AuthWeakPasswordException(
          message: 'Password is too weak',
          statusCode: '422',
          reasons: const ['length', 'characters'],
        ),
      );

      expect(mapped, contains('Minimum password length'));
      expect(mapped, contains('Password Requirements'));
    });

    test('mappe same_password via code', () {
      expect(
        AuthErrorMapper.map(
          const AuthApiException(
            'New password should be different from the old password.',
            statusCode: '422',
            code: 'same_password',
          ),
        ),
        contains('différent'),
      );
    });

    test('mappe session manquante clairement', () {
      expect(
        AuthErrorMapper.map(AuthSessionMissingException()),
        contains('expiré'),
      );
    });

    test('surface le message Auth pour une politique password générique', () {
      final mapped = AuthErrorMapper.map(
        const AuthApiException(
          'Password should contain at least one character of each: abcdefghijklmnopqrstuvwxyz, ABCDEFGHIJKLMNOPQRSTUVWXYZ, 0123456789',
          statusCode: '422',
          code: 'weak_password',
        ),
      );

      expect(mapped, isNot(equals('Mot de passe invalide.')));
      expect(mapped.toLowerCase(), contains('faible'));
    });

    test('conserve le mapping login credentials', () {
      expect(
        AuthErrorMapper.map(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
          ),
        ),
        'E-mail ou mot de passe incorrect.',
      );
    });
  });
}
