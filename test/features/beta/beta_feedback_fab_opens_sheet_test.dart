import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/design_system/theme/atlas_colors.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/beta/data/beta_feedback_repository.dart';
import 'package:atlas/features/beta/presentation/beta_feedback_scope.dart';
import 'package:atlas/features/beta/presentation/widgets/beta_feedback_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'rendered Signaler FAB receives tap and opens visible sheet '
    '(AppShell-shaped tree + rootNavigator)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = BetaFeedbackRepository(
        authRepository: _StubAuthRepository(),
      );
      await repository.load();

      var pressed = false;

      // Mirrors AppShell: BetaFeedbackScope → Scaffold → FAB Builder with
      // FloatingActionButton.small + explicit repository + rootNavigator sheet.
      await tester.pumpWidget(
        MaterialApp(
          home: BetaFeedbackScope(
            repository: repository,
            child: Scaffold(
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              floatingActionButton: Builder(
                builder: (fabContext) {
                  return FloatingActionButton.small(
                    key: const Key('atlas_beta_feedback_fab'),
                    heroTag: 'atlas_beta_feedback_fab',
                    tooltip: 'Signaler (bêta)',
                    backgroundColor: AtlasColors.surfaceWhite,
                    onPressed: () {
                      pressed = true;
                      showBetaFeedbackSheet(
                        context: fabContext,
                        screenName: 'home',
                        repository: repository,
                      );
                    },
                    child: const Icon(Icons.flag_outlined, size: 20),
                  );
                },
              ),
              body: const SizedBox.expand(),
              bottomNavigationBar: const SizedBox(height: 64),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fab = find.byKey(const Key('atlas_beta_feedback_fab'));
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pump(); // schedule sheet route
      await tester.pumpAndSettle();

      expect(pressed, isTrue, reason: 'FAB onPressed must fire');
      expect(find.text('Signaler (bêta privée)'), findsOneWidget);
      expect(find.text('Bug'), findsOneWidget);
      expect(find.text('Info incorrecte'), findsOneWidget);
      expect(find.text('Problème d’usage'), findsOneWidget);
      expect(find.text('Autre'), findsOneWidget);
      expect(find.text('Envoyer'), findsOneWidget);
    },
  );

  testWidgets(
    'wrong AppShell-style context without repository throws clearly',
    (tester) async {
      final repository = BetaFeedbackRepository(
        authRepository: _StubAuthRepository(),
      );
      await repository.load();

      late BuildContext outerContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              outerContext = context;
              return BetaFeedbackScope(
                repository: repository,
                child: const Scaffold(body: SizedBox.expand()),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // outerContext is ABOVE BetaFeedbackScope — the old FAB bug.
      expect(
        () => BetaFeedbackScope.of(outerContext),
        throwsA(isA<FlutterError>()),
      );
    },
  );
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
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> signOut() async => AuthActionResult.success();

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
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> cancelPasswordRecovery() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> deleteAccount() async => AuthActionResult.success();
}
