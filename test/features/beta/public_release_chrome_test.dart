import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/core/platform/atlas_build_info.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/beta/presentation/pages/beta_diagnostics_page.dart';
import 'package:atlas/features/beta/presentation/widgets/atlas_beta_banner.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/shell/presentation/app_shell.dart';

import '../onboarding/onboarding_test_helpers.dart';
import '../prices/price_intelligence_test_helpers.dart';

const _buildInfo = AtlasBuildInfo(
  appName: 'Atlas',
  packageName: 'app.atlas.maroc',
  version: '1.0.0',
  buildNumber: '6',
  platformLabel: 'ios',
  deviceLabel: 'iPhone',
);

const _productionUrl = 'https://abcdefghijklmnop.supabase.co';
const _productionAnon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.public';

const _betaEnv = AtlasEnv(
  environment: AtlasEnvironment.production,
  supabaseUrl: _productionUrl,
  supabaseAnonKey: _productionAnon,
  showBetaFeedback: true,
);

const _publicEnv = AtlasEnv(
  environment: AtlasEnvironment.production,
  supabaseUrl: _productionUrl,
  supabaseAnonKey: _productionAnon,
  showBetaFeedback: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    ensurePrayerNotificationCoordinatorForTests();
    ensureAtRepositoryForTests();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  setUp(() {
    seedCompletedOnboarding();
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    resetAtBootstrapForTests();
    ensureAtRepositoryForTests();
    PlaceBrowseFilters.resetForTest();
    AtlasFlutterMapView.useSilentTiles = true;
    AtlasBuildInfo.debugOverride(_buildInfo);
  });

  tearDown(() {
    AtlasBuildInfo.debugOverride(null);
    PriceIntelligenceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    required AtlasEnv env,
    bool skipBetaPrompts = true,
  }) async {
    final profile = LocalProfileRepository();
    await profile.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          env: env,
          skipBetaPrompts: skipBetaPrompts,
          authRepository: _StubAuthRepository(),
          profileRepository: profile,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('flag true : bandeau, FAB et diagnostics accessibles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpShell(tester, env: _betaEnv);

    expect(find.byType(AtlasBetaBanner), findsOneWidget);
    expect(find.textContaining('Atlas Private Beta'), findsOneWidget);
    expect(find.byKey(const Key('atlas_beta_feedback_fab')), findsOneWidget);

    final banner = find.byType(AtlasBetaBanner);
    for (var i = 0; i < 7; i++) {
      await tester.tap(banner);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    expect(find.byType(BetaDiagnosticsPage), findsOneWidget);
    expect(find.text('Diagnostics beta'), findsOneWidget);
  });

  testWidgets('flag true : dialogue d’accueil et Nouveautés Private Beta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpShell(tester, env: _betaEnv, skipBetaPrompts: false);

    expect(find.text('Bienvenue dans la bêta Atlas'), findsOneWidget);
    expect(find.textContaining('bêta privée'), findsOneWidget);
    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveautés Atlas'), findsOneWidget);
    expect(find.textContaining('Private Beta'), findsWidgets);
    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();

    expect(find.byType(AtlasBetaBanner), findsOneWidget);
    expect(find.byKey(const Key('atlas_beta_feedback_fab')), findsOneWidget);
  });

  testWidgets(
    'flag false : aucun bandeau, dialogue, diagnostic ni texte Private Beta',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpShell(tester, env: _publicEnv, skipBetaPrompts: false);

      expect(find.byType(AtlasBetaBanner), findsNothing);
      expect(find.byKey(const Key('atlas_beta_feedback_fab')), findsNothing);
      expect(find.byType(BetaDiagnosticsPage), findsNothing);
      expect(find.textContaining('Private Beta'), findsNothing);
      expect(find.textContaining('private beta'), findsNothing);
      expect(find.textContaining('bêta privée'), findsNothing);
      expect(find.text('Bienvenue dans la bêta Atlas'), findsNothing);
      expect(find.text('Nouveautés Atlas'), findsNothing);
      expect(find.text('Diagnostics beta'), findsNothing);
      expect(find.text('Signaler (bêta)'), findsNothing);
      expect(find.text('Signaler (bêta privée)'), findsNothing);
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
