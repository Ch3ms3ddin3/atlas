import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/auth/presentation/widgets/profile_account_section.dart';

void main() {
  testWidgets('ProfileAccountSection affiche le mode local sans backend', (
    WidgetTester tester,
  ) async {
    final repository = _StubAuthRepository(
      session: const AuthSession.unavailable(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          repository: repository,
          child: const Scaffold(
            body: ProfileAccountSection(),
          ),
        ),
      ),
    );

    expect(find.text('Compte Atlas'), findsOneWidget);
    expect(
      find.textContaining('Mode hors ligne'),
      findsOneWidget,
    );
    expect(
      find.text('Aucun compte · données stockées localement'),
      findsOneWidget,
    );
    expect(find.text('Créer un compte'), findsNothing);
  });

  testWidgets('ProfileAccountSection propose connexion en session invitée', (
    WidgetTester tester,
  ) async {
    final repository = _StubAuthRepository(
      session: const AuthSession(
        kind: AuthSessionKind.anonymous,
        userId: 'guest-1',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          repository: repository,
          child: const Scaffold(
            body: ProfileAccountSection(),
          ),
        ),
      ),
    );

    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository({required this.session}) : super.base();

  @override
  final AuthSession session;

  @override
  bool get isLoaded => true;

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
    return AuthActionResult.success();
  }
}
