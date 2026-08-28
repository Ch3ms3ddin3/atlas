import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/platform/atlas_build_info.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/auth/presentation/widgets/auth_form_sheet.dart';
import 'package:atlas/features/beta/presentation/widgets/atlas_beta_banner.dart';

void main() {
  testWidgets('auth sheet hides Apple/Google by default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          repository: _StubAuthRepository(),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: FilledButton(
                    onPressed: () => AuthFormSheet.show(
                      context,
                      initialMode: AuthFormMode.signIn,
                    ),
                    child: const Text('Ouvrir'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Continuer avec Apple'), findsNothing);
    expect(find.text('Continuer avec Google'), findsNothing);
    expect(find.text('Se connecter'), findsWidgets);
    expect(find.text('E-mail'), findsOneWidget);
  });

  testWidgets('auth sheet shows Apple/Google when explicitly enabled', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          repository: _StubAuthRepository(),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: FilledButton(
                    onPressed: () => AuthFormSheet.show(
                      context,
                      initialMode: AuthFormMode.signIn,
                      showSocialAuth: true,
                    ),
                    child: const Text('Ouvrir'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Continuer avec Apple'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
  });

  testWidgets('beta banner states Marrakech only when location is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtlasBetaBanner(
            buildInfo: const AtlasBuildInfo(
              appName: 'Atlas',
              packageName: 'app.atlas.maroc',
              version: '1.0.0',
              buildNumber: '42',
              platformLabel: 'ios',
              deviceLabel: 'iPhone',
            ),
            locationLabel: 'Marrakech',
          ),
        ),
      ),
    );

    expect(find.text('Atlas Private Beta · Marrakech'), findsOneWidget);
  });

  testWidgets('beta banner omits Marrakech without a real location', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtlasBetaBanner(
            buildInfo: const AtlasBuildInfo(
              appName: 'Atlas',
              packageName: 'app.atlas.maroc',
              version: '1.0.0',
              buildNumber: '42',
              platformLabel: 'ios',
              deviceLabel: 'iPhone',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Atlas Private Beta'), findsOneWidget);
    expect(find.text('Atlas Private Beta · Marrakech'), findsNothing);
  });
}

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository() : super.base();

  @override
  AuthSession get session =>
      const AuthSession(kind: AuthSessionKind.anonymous, userId: 'guest-1');

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
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> signOut() async => AuthActionResult.success();

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> resetPassword({required String email}) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> cancelPasswordRecovery() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithApple() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithGoogle() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> deleteAccount() async => AuthActionResult.success();
}
