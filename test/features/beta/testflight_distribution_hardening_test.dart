import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/core/platform/atlas_build_info.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/beta/data/beta_preferences_store.dart';
import 'package:atlas/features/beta/presentation/widgets/atlas_beta_banner.dart';
import 'package:atlas/features/beta/presentation/widgets/private_beta_expectations_dialog.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:atlas/features/shell/presentation/shell_tab_scroll_registry.dart';
import 'package:atlas/features/sync/data/syncing_user_preferences_repository.dart';
import 'package:atlas/features/sync/presentation/sync_scope.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/presentation/at_scope.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AtlasEnv Milestone 2 flags', () {
    test('experimental surfaces off, beta feedback on by default', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(env.showExperimentalSurfaces, isFalse);
      expect(env.showBetaFeedback, isTrue);
      expect(env.showSocialAuth, isFalse);
    });

    test('staging refuses empty credentials', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(env.requiresHardenedSupabaseCredentials, isTrue);
      expect(env.hardenedCredentialsIssue, isNotNull);
    });

    test('production refuses example placeholders', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.production,
        supabaseUrl: 'https://YOUR-PRODUCTION-PROJECT.supabase.co',
        supabaseAnonKey: 'your-production-anon-key',
      );
      expect(env.looksLikePlaceholderCredentials, isTrue);
      expect(env.hardenedCredentialsIssue, isNotNull);
    });

    test('development allows empty local credentials', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      // Not release mode in tests → no hardened requirement for development.
      expect(env.requiresHardenedSupabaseCredentials, isFalse);
      expect(env.hardenedCredentialsIssue, isNull);
    });

    test('real-looking staging credentials pass validation', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: 'https://abcdefghijklmnop.supabase.co',
        supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.staging',
      );
      expect(env.looksLikePlaceholderCredentials, isFalse);
      expect(env.hardenedCredentialsIssue, isNull);
    });
  });

  testWidgets('private beta expectations dialog copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () =>
                    showPrivateBetaExpectationsDialog(context: context),
                child: const Text('Ouvrir'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue dans la bêta Atlas'), findsOneWidget);
    expect(find.textContaining('centrée sur Marrakech'), findsOneWidget);
    expect(find.textContaining('Signaler'), findsOneWidget);
    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();
  });

  testWidgets('profile hides Assistant and Itinéraires by default', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final profile = LocalProfileRepository();
    await profile.load();
    final auth = _StubAuthRepository();
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    final at = LocalAtRepository();
    await at.load();
    final prefs = SyncingUserPreferencesRepository();
    await prefs.load();

    await tester.pumpWidget(
      AuthScope(
        repository: auth,
        child: ProfileScope(
          repository: profile,
          child: FavoritesScope(
            repository: favorites,
            child: AtScope(
              repository: at,
              child: SyncScope(
                repository: prefs,
                child: ShellNavigationScope(
                  navigateToTab: (_) {},
                  scrollRegistry: ShellTabScrollRegistry(),
                  child: const MaterialApp(home: Scaffold(body: ProfilePage())),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assistant Atlas'), findsNothing);
    expect(find.text('Itinéraires Atlas'), findsNothing);
    expect(find.text('Favoris'), findsWidgets);
  });

  testWidgets('beta banner remains Marrakech-first', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtlasBetaBanner(
            buildInfo: const AtlasBuildInfo(
              appName: 'Atlas',
              packageName: 'app.atlas.maroc',
              version: '1.0.0',
              buildNumber: '2',
              platformLabel: 'ios',
              deviceLabel: 'iPhone',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Atlas Private Beta · Marrakech'), findsOneWidget);
  });

  test('beta preferences store tracks expectations seen', () async {
    const store = BetaPreferencesStore();
    expect(await store.loadPrivateBetaExpectationsSeen(), isFalse);
    await store.savePrivateBetaExpectationsSeen(seen: true);
    expect(await store.loadPrivateBetaExpectationsSeen(), isTrue);
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
