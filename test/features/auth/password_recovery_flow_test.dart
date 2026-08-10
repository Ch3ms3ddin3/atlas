import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/auth/presentation/widgets/auth_password_recovery_listener.dart';
import 'package:atlas/features/auth/presentation/widgets/password_recovery_sheet.dart';

void main() {
  testWidgets(
    'PASSWORD_RECOVERY ouvre la feuille et enregistre le nouveau mot de passe',
    (tester) async {
      final auth = _RecoveryAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: auth,
            child: const AuthPasswordRecoveryListener(
              child: Scaffold(body: Text('shell')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      auth.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      expect(find.byType(PasswordRecoverySheet), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Enregistrer le mot de passe'),
        findsOneWidget,
      );

      final fields = find.descendant(
        of: find.byType(PasswordRecoverySheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'nouveau12');
      await tester.enterText(fields.at(1), 'nouveau12');
      await tester.tap(find.text('Enregistrer le mot de passe'));
      await tester.pumpAndSettle();

      expect(auth.updatePasswordCalls, 1);
      expect(auth.lastNewPassword, 'nouveau12');
      expect(auth.isPasswordRecoveryPending, isFalse);
      expect(
        find.textContaining('Mot de passe mis à jour'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'annuler le recovery nettoie la session pending',
    (tester) async {
      final auth = _RecoveryAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: auth,
            child: const AuthPasswordRecoveryListener(
              child: Scaffold(body: Text('shell')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      auth.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(auth.cancelCalls, greaterThanOrEqualTo(1));
      expect(auth.isPasswordRecoveryPending, isFalse);
      expect(find.byType(PasswordRecoverySheet), findsNothing);
    },
  );

  testWidgets(
    'affiche la raison réelle si updatePassword échoue (pas Mot de passe invalide)',
    (tester) async {
      final auth = _RecoveryAuthRepository(
        updateResult: AuthActionResult.failure(
          'Mot de passe trop faible : trop court '
          '(Minimum password length dans Auth → Email).',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: auth,
            child: const AuthPasswordRecoveryListener(
              child: Scaffold(body: Text('shell')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      auth.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      final fields = find.descendant(
        of: find.byType(PasswordRecoverySheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Nouveau#Pass9');
      await tester.enterText(fields.at(1), 'Nouveau#Pass9');
      await tester.tap(find.text('Enregistrer le mot de passe'));
      await tester.pumpAndSettle();

      expect(auth.updatePasswordCalls, 1);
      expect(auth.isPasswordRecoveryPending, isTrue);
      expect(find.byType(PasswordRecoverySheet), findsOneWidget);
      expect(find.textContaining('Mot de passe trop faible'), findsOneWidget);
      expect(find.text('Mot de passe invalide.'), findsNothing);
    },
  );
}

class _RecoveryAuthRepository extends AuthRepository {
  _RecoveryAuthRepository({AuthActionResult? updateResult})
      : _updateResult = updateResult ?? AuthActionResult.success(),
        super.base();

  final AuthActionResult _updateResult;
  bool _pending = false;
  int updatePasswordCalls = 0;
  int cancelCalls = 0;
  String? lastNewPassword;

  void triggerPasswordRecovery() {
    _pending = true;
    notifyListeners();
  }

  @override
  AuthSession get session => const AuthSession(
        kind: AuthSessionKind.signedIn,
        userId: 'user-recovery',
        email: 'salma@exemple.com',
      );

  @override
  bool get isLoaded => true;

  @override
  bool get isPasswordRecoveryPending => _pending;

  @override
  Future<void> load() async {}

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success(requiresEmailConfirmation: true);

  @override
  Future<AuthActionResult> signInWithApple() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithGoogle() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> resetPassword({required String email}) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    updatePasswordCalls += 1;
    lastNewPassword = newPassword;
    if (_updateResult.success) {
      _pending = false;
    }
    notifyListeners();
    return _updateResult;
  }

  @override
  Future<AuthActionResult> cancelPasswordRecovery() async {
    cancelCalls += 1;
    _pending = false;
    notifyListeners();
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> signOut() async {
    _pending = false;
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> deleteAccount() async =>
      AuthActionResult.success();
}
