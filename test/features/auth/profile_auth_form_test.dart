import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/auth/presentation/widgets/auth_form_sheet.dart';

void main() {
  testWidgets(
    'AuthFormSheet inscription affiche un succès honnête (confirmation e-mail)',
    (WidgetTester tester) async {
      final authRepository = _RecordingAuthRepository(
        session: const AuthSession(
          kind: AuthSessionKind.anonymous,
          userId: 'guest-1',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: authRepository,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: FilledButton(
                      onPressed: () => AuthFormSheet.show(
                        context,
                        initialMode: AuthFormMode.signUp,
                      ),
                      child: const Text('Ouvrir inscription'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ouvrir inscription'));
      await tester.pumpAndSettle();

      expect(find.text('Créer mon compte'), findsOneWidget);
      expect(
        find.textContaining('confirmation d\'adresse'),
        findsOneWidget,
      );

      final authFields = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      expect(authFields, findsNWidgets(3));

      await tester.enterText(authFields.at(0), 'salma@exemple.com');
      await tester.enterText(authFields.at(1), 'secret12');
      await tester.enterText(authFields.at(2), 'secret12');

      await tester.ensureVisible(find.text('Créer mon compte'));
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();

      expect(authRepository.signUpCalls, 1);
      expect(authRepository.lastSignUpEmail, 'salma@exemple.com');
      expect(
        find.textContaining('Vérifiez votre e-mail pour confirmer le compte'),
        findsOneWidget,
      );
      expect(find.text('Créer mon compte'), findsNothing);
    },
  );
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository({required this._session}) : super.base();

  AuthSession _session;
  int signUpCalls = 0;
  String? lastSignUpEmail;

  @override
  AuthSession get session => _session;

  @override
  bool get isLoaded => true;

  @override
  bool get isPasswordRecoveryPending => false;

  @override
  Future<void> load() async {}

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> signOut() async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    lastSignUpEmail = email;
    _session = AuthSession(
      kind: AuthSessionKind.signedIn,
      userId: 'user-1',
      email: email,
    );
    notifyListeners();
    return AuthActionResult.success(requiresEmailConfirmation: true);
  }

  @override
  Future<AuthActionResult> signInWithApple() async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> signInWithGoogle() async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> cancelPasswordRecovery() async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> resetPassword({required String email}) async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> deleteAccount() async {
    return AuthActionResult.success();
  }
}
