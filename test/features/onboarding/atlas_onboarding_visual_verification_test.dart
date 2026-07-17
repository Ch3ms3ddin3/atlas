import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/presentation/at_scope.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/auth/presentation/widgets/auth_form_sheet.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/onboarding/data/onboarding_preferences_store.dart';
import 'package:atlas/features/onboarding/presentation/pages/onboarding_flow.dart';
import 'package:atlas/features/onboarding/presentation/startup_gate.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/app_shell.dart';

import 'onboarding_test_helpers.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({AuthSession? session})
      : _session = session ?? const AuthSession.unavailable(),
        super.base();

  final AuthSession _session;

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
  }) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success();

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
  Future<AuthActionResult> deleteAccount() async => AuthActionResult.success();
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
  });

  Future<void> pumpFlow(
    WidgetTester tester, {
    required Size size,
    LocalProfileRepository? profile,
    AuthRepository? auth,
  }) async {
    final profileRepo = profile ?? LocalProfileRepository();
    if (!profileRepo.isLoaded) await profileRepo.load();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: AuthScope(
          repository: auth ?? _FakeAuthRepository(),
          child: ProfileScope(
            repository: profileRepo,
            child: OnboardingFlow(onCompleted: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('visual checklist — mobile', () {
    testWidgets('city / language / profile required selections persist', (
      tester,
    ) async {
      final profile = LocalProfileRepository();
      await pumpFlow(tester, size: const Size(800, 1400), profile: profile);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.text('Marrakech'), findsWidgets);
      expect(find.text('Résident'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);

      await tester.tap(find.text('Rabat'));
      await tester.pump();
      await tester.tap(find.text('English'));
      await tester.pump();
      await tester.ensureVisible(find.text('Étudiant'));
      await tester.tap(find.text('Étudiant'));
      await tester.pump();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(profile.profile.preferredCity, 'Rabat');
      expect(profile.profile.language, AtlasLanguage.english);
      expect(profile.profile.userType, AtlasUserType.student);
      expect(find.text('Continuer sans compte'), findsOneWidget);
    });

    testWidgets('Sign in et Create account ouvrent AuthFormSheet', (
      tester,
    ) async {
      await pumpFlow(tester, size: const Size(800, 1400));
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthFormSheet), findsOneWidget);
      expect(find.text('Se connecter'), findsWidgets);

      Navigator.of(tester.element(find.byType(AuthFormSheet))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthFormSheet), findsOneWidget);
      expect(find.text('Créer un compte'), findsWidgets);
    });

    testWidgets('notifications : opt-in explicite seulement', (tester) async {
      await pumpFlow(tester, size: const Size(800, 1400));
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(find.text('Rappels utiles'), findsOneWidget);
    });
  });

  group('visual checklist — web', () {
    testWidgets('layout large + auth CTAs', (tester) async {
      await pumpFlow(tester, size: const Size(1280, 900));
      expect(find.text('Votre compagnon au Maroc'), findsOneWidget);

      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      expect(find.text('Personnalisez Atlas'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('Continuer sans compte'), findsOneWidget);
    });
  });

  testWidgets('reset onboarding depuis Profil', (tester) async {
    seedCompletedOnboarding();
    final profile = LocalProfileRepository();
    await profile.load();
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    final at = LocalAtRepository();
    await at.load();

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: AuthScope(
          repository: _FakeAuthRepository(),
          child: ProfileScope(
            repository: profile,
            child: FavoritesScope(
              repository: favorites,
              child: AtScope(
                repository: at,
                child: const Scaffold(body: ProfilePage()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(await const OnboardingPreferencesStore().isCompleted(), isTrue);
    expect(find.text('Réafficher l\'introduction'), findsOneWidget);
    await tester.tap(find.text('Réafficher l\'introduction'));
    await tester.pumpAndSettle();
    expect(await const OnboardingPreferencesStore().isCompleted(), isFalse);
    expect(find.textContaining('Introduction réinitialisée'), findsOneWidget);
  });

  testWidgets('signed-in conserve les valeurs profil', (tester) async {
    final profile = LocalProfileRepository();
    await profile.load();
    await profile.save(
      const UserProfile(
        firstName: 'Salma',
        preferredCity: 'Fès',
        language: AtlasLanguage.arabic,
        userType: AtlasUserType.expatriate,
      ),
    );

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
              email: 'salma@example.com',
            ),
          ),
          profileRepository: profile,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppShell), findsOneWidget);
    expect(profile.profile.firstName, 'Salma');
    expect(profile.profile.preferredCity, 'Fès');
    expect(profile.profile.language, AtlasLanguage.arabic);
    expect(profile.profile.userType, AtlasUserType.expatriate);
  });
}
