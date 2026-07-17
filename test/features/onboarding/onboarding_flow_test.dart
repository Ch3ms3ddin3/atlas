import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/onboarding/data/onboarding_preferences_store.dart';
import 'package:atlas/features/onboarding/presentation/pages/onboarding_flow.dart';
import 'package:atlas/features/onboarding/presentation/startup_gate.dart';
import 'package:atlas/features/onboarding/presentation/widgets/atlas_splash_view.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/app_shell.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';

import 'onboarding_test_helpers.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({AuthSession? session})
      : _session = session ?? const AuthSession.unavailable(),
        super.base();

  AuthSession _session;
  bool loaded = false;

  @override
  AuthSession get session => _session;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load() async {
    loaded = true;
    notifyListeners();
  }

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    _session = AuthSession(
      kind: AuthSessionKind.signedIn,
      userId: 'u1',
      email: email,
    );
    notifyListeners();
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async {
    return signIn(email: email, password: password);
  }

  @override
  Future<AuthActionResult> signOut() async {
    _session = const AuthSession.unavailable();
    notifyListeners();
    return AuthActionResult.success();
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
  Future<AuthActionResult> resetPassword({required String email}) async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> deleteAccount() async {
    return AuthActionResult.success();
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
    ensureAtRepositoryForTests();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorialRepositoryBootstrap.registerDefaults();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  test('persiste la completion et ne la rejoue pas', () async {
    const store = OnboardingPreferencesStore();
    expect(await store.isCompleted(), isFalse);
    await store.markCompleted();
    expect(await store.isCompleted(), isTrue);
    await store.reset();
    expect(await store.isCompleted(), isFalse);
  });

  test('migration : profil déjà sauvé saute l\'onboarding', () async {
    SharedPreferences.setMockInitialValues({
      ProfilePreferencesStore.localUpdatedAtKey:
          DateTime.utc(2026, 7, 1).toIso8601String(),
    });
    const store = OnboardingPreferencesStore();
    expect(await store.isCompleted(), isTrue);
  });

  testWidgets('premier lancement affiche l\'accueil Atlas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: StartupGate(
          authRepository: _FakeAuthRepository(),
          profileRepository: LocalProfileRepository(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(AtlasSplashView), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Votre compagnon au Maroc'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('parcours 3 écrans puis Accueil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final profile = LocalProfileRepository();
    await profile.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: StartupGate(
          authRepository: _FakeAuthRepository(),
          profileRepository: profile,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Personnalisez Atlas'), findsOneWidget);
    await tester.tap(find.text('Casablanca'));
    await tester.pump();
    await tester.tap(find.text('Touriste'));
    await tester.pump();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Continuer sans compte'), findsOneWidget);
    await tester.tap(find.text('Continuer sans compte'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(await const OnboardingPreferencesStore().isCompleted(), isTrue);
    expect(profile.profile.preferredCity, 'Casablanca');
    expect(profile.profile.userType, AtlasUserType.tourist);
  });

  testWidgets('utilisateur déjà onboardé arrive sur Accueil', (tester) async {
    seedCompletedOnboarding();
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: StartupGate(
          authRepository: _FakeAuthRepository(),
          profileRepository: LocalProfileRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Votre compagnon au Maroc'), findsNothing);
  });

  testWidgets('compte connecté saute l\'onboarding', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: StartupGate(
          authRepository: _FakeAuthRepository(
            session: const AuthSession(
              kind: AuthSessionKind.signedIn,
              userId: 'u1',
              email: 'a@b.c',
            ),
          ),
          profileRepository: LocalProfileRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppShell), findsOneWidget);
    expect(await const OnboardingPreferencesStore().isCompleted(), isTrue);
  });

  testWidgets('layout web large du parcours', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final profile = LocalProfileRepository();
    await profile.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: AuthScope(
          repository: _FakeAuthRepository(),
          child: ProfileScope(
            repository: profile,
            child: OnboardingFlow(onCompleted: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre compagnon au Maroc'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
  });

  testWidgets('accessibilité : progression annoncée', (tester) async {
    final profile = LocalProfileRepository();
    await profile.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: AuthScope(
          repository: _FakeAuthRepository(),
          child: ProfileScope(
            repository: profile,
            child: OnboardingFlow(onCompleted: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Étape 1 sur 3'), findsOneWidget);
  });
}
