import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ensurePrayerNotificationCoordinatorForTests();
  });

  testWidgets(
    'ProfilePage soumet la création de compte via AuthFormSheet',
    (WidgetTester tester) async {
      final authRepository = _RecordingAuthRepository(
        session: const AuthSession(
          kind: AuthSessionKind.anonymous,
          userId: 'guest-1',
        ),
      );
      final profileRepository = LocalProfileRepository();
      await profileRepository.load();

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: authRepository,
            child: ProfileScope(
              repository: profileRepository,
              child: const Scaffold(
                body: ProfilePage(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final createAccountButton = find.text('Créer un compte');
      await tester.ensureVisible(createAccountButton);
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      expect(find.text('Créer mon compte'), findsOneWidget);

      final authFields = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      expect(authFields, findsNWidgets(3));

      await tester.enterText(authFields.at(0), 'salma@exemple.com');
      await tester.enterText(authFields.at(1), 'secret12');
      await tester.enterText(authFields.at(2), 'secret12');

      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();

      expect(authRepository.signUpCalls, 1);
      expect(authRepository.lastSignUpEmail, 'salma@exemple.com');
      expect(
        find.text('Compte créé — vos données restent sur cet appareil.'),
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
    return AuthActionResult.success();
  }
}
