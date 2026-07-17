import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/resilient_place_repository.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/presentation/at_scope.dart';
import 'package:atlas/features/assistant/data/local_assistant_repository.dart';
import 'package:atlas/features/assistant/data/providers/mock_assistant_provider.dart';
import 'package:atlas/features/assistant/domain/models/assistant_context_snapshot.dart';
import 'package:atlas/features/assistant/presentation/assistant_scope.dart';
import 'package:atlas/features/itineraries/data/syncing_itinerary_repository.dart';
import 'package:atlas/features/itineraries/presentation/itinerary_scope.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/home/presentation/pages/home_page.dart';
import 'package:atlas/features/prices/data/local_price_repository.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/data/resilient_price_repository.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/price_repository.dart';
import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/data/resilient_procedure_repository.dart';
import 'package:atlas/features/procedures/domain/procedure_repository.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:atlas/features/profile/domain/profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';

import '../onboarding/onboarding_test_helpers.dart';
import '../prices/price_intelligence_test_helpers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  setUp(() async {
    seedCompletedOnboarding();
    PlaceRepository.resetForTest();
    PriceRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    resetAtBootstrapForTests();
    ensureAtRepositoryForTests();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
    PriceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
    resetAtBootstrapForTests();
  });

  Future<void> pumpHomeDashboard(
    WidgetTester tester, {
    required ProfileRepository profile,
    required FavoritesRepository favorites,
  }) async {
    await profile.load();
    await favorites.load();
    final atRepository = LocalAtRepository();
    await atRepository.load();
    ensureAtRepositoryForTests(repository: atRepository);

    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: ProfileScope(
          repository: profile,
          child: FavoritesScope(
            repository: favorites,
            child: AtScope(
              repository: atRepository,
              child: AssistantScope(
                repository: LocalAssistantRepository(
                  profileRepository: profile,
                  authRepository: _HomeTestAuthRepository(),
                  favoritesRepository: favorites,
                  atRepository: atRepository,
                  provider: MockAssistantProvider(chunkDelay: Duration.zero),
                  contextProvider: () async => const AssistantContextSnapshot(
                    city: 'Marrakech',
                    userType: 'resident',
                    language: 'french',
                    authKind: 'unavailable',
                    isSignedIn: false,
                  ),
                ),
                child: ItineraryScope(
                  repository: SyncingItineraryRepository(
                    favoritesRepository: favorites,
                  ),
                  child: ShellNavigationScope(
                    navigateToTab: (_) {},
                    child: const Scaffold(body: HomePage()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('first launch: briefing and core sections render', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Voyageur'), findsOneWidget);
    expect(find.text('Briefing du jour'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Mes véhicules au Maroc'), findsOneWidget);
    expect(find.text('Ajouter un véhicule'), findsOneWidget);
    expect(find.text('Actions rapides'), findsOneWidget);
    expect(find.text('Démarches utiles'), findsOneWidget);
    expect(find.text('Prix à la une'), findsOneWidget);
  });

  testWidgets('signed out / local profile: default greeting, no favorites', (
    WidgetTester tester,
  ) async {
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();

    await pumpHomeDashboard(
      tester,
      profile: profile,
      favorites: favorites,
    );

    expect(find.text('Bonjour, Voyageur'), findsOneWidget);
    expect(find.text('Mes favoris'), findsNothing);
    expect(find.text('Recommandations'), findsOneWidget);
    expect(find.text('Urgences'), findsNothing);
  });

  testWidgets('signed in profile: personalized greeting updates Home', (
    WidgetTester tester,
  ) async {
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    await profile.load();
    await profile.save(
      UserProfile.defaults.copyWith(firstName: 'Salma'),
    );

    await pumpHomeDashboard(
      tester,
      profile: profile,
      favorites: favorites,
    );

    expect(find.text('Bonjour, Salma'), findsOneWidget);
    expect(find.text('Bonjour, Voyageur'), findsNothing);
  });

  testWidgets('no favorites: Mes favoris section is hidden', (
    WidgetTester tester,
  ) async {
    await pumpHomeDashboard(
      tester,
      profile: LocalProfileRepository(),
      favorites: LocalFavoritesRepository(),
    );

    expect(find.text('Mes favoris'), findsNothing);
  });

  testWidgets('with favorites: Mes favoris shows all entity types', (
    WidgetTester tester,
  ) async {
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    await favorites.addFavorite(
      entityType: FavoriteEntityType.place,
      entitySlug: 'place-majorelle',
    );
    await favorites.addFavorite(
      entityType: FavoriteEntityType.procedure,
      entitySlug: 'cin-renewal',
    );
    await favorites.addFavorite(
      entityType: FavoriteEntityType.price,
      entitySlug: 'taxi-airport-marrakech',
    );

    await pumpHomeDashboard(
      tester,
      profile: LocalProfileRepository(),
      favorites: favorites,
    );

    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsWidgets);
    expect(find.text('Renouveler la CIN'), findsWidgets);
    expect(find.text('Taxi Airport Marrakech'), findsWidgets);
    expect(find.text('Lieu'), findsOneWidget);
    expect(find.text('Démarche'), findsOneWidget);
    expect(find.text('Prix'), findsWidgets);
  });

  testWidgets('no recommendations: Recommandations section is hidden', (
    WidgetTester tester,
  ) async {
    PlaceRepository.registerFactory(
      () => _EmptyFeaturedPlaceRepository(),
    );

    await pumpHomeDashboard(
      tester,
      profile: LocalProfileRepository(),
      favorites: LocalFavoritesRepository(),
    );

    expect(find.text('Recommandations'), findsNothing);
    expect(find.text('Jardin Majorelle'), findsNothing);
    expect(find.text('Briefing du jour'), findsOneWidget);
    expect(find.text('Démarches utiles'), findsOneWidget);
  });

  testWidgets('offline APIs: Home still renders without invented weather', (
    WidgetTester tester,
  ) async {
    // TestWidgetsFlutterBinding returns HTTP 400 for all requests.
    await pumpHomeDashboard(
      tester,
      profile: LocalProfileRepository(),
      favorites: LocalFavoritesRepository(),
    );

    expect(find.text('Briefing du jour'), findsOneWidget);
    expect(find.text('Météo indisponible'), findsOneWidget);
    expect(find.text('Horaires indisponibles'), findsOneWidget);
    expect(find.text('Taux indisponible'), findsOneWidget);
    expect(find.text('Forte chaleur prévue'), findsNothing);
    expect(find.textContaining('données estimées'), findsWidgets);
    expect(find.text('Actions rapides'), findsOneWidget);
    expect(find.text('Prix à la une'), findsOneWidget);
  });

  testWidgets('empty remote catalogs: local fallback keeps Home usable', (
    WidgetTester tester,
  ) async {
    PlaceRepository.registerFactory(
      () => ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => const [],
      ),
    );
    PriceRepository.registerFactory(
      () => ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => const [],
      ),
    );
    PriceIntelligenceRepository.registerFactory(
      () => ResilientPriceIntelligenceRepository(
        fetchRemote: () async => const [],
      ),
    );
    ProcedureRepository.registerFactory(
      () => ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => const [],
      ),
    );

    final places = PlaceRepository();
    final prices = PriceRepository();
    final intelligence = PriceIntelligenceRepository();
    final procedures = ProcedureRepository();
    await Future.wait([
      places.warmUp(),
      prices.warmUp(),
      intelligence.warmUp(),
      procedures.warmUp(),
    ]);

    await pumpHomeDashboard(
      tester,
      profile: LocalProfileRepository(),
      favorites: LocalFavoritesRepository(),
    );

    expect(find.text('Recommandations'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    // Intelligence : pas de données vérifiées → section masquée (pas de faux prix).
    expect(find.text('Prix à la une'), findsNothing);
    expect(find.text('SP95 Marrakech'), findsNothing);
    expect(find.text('Démarches utiles'), findsOneWidget);
    expect(find.textContaining('Admission temporaire'), findsOneWidget);
  });
}

class _HomeTestAuthRepository extends AuthRepository {
  _HomeTestAuthRepository() : super.base();

  @override
  AuthSession get session => const AuthSession.unavailable();

  @override
  bool get isLoaded => true;

  @override
  Future<void> load() async {}

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success();

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
  Future<AuthActionResult> signOut() async => AuthActionResult.success();

  @override
  Future<AuthActionResult> deleteAccount() async =>
      AuthActionResult.success();
}

/// Place repository whose featured list is always empty (section must hide).
class _EmptyFeaturedPlaceRepository extends LocalPlaceRepository {
  @override
  List<PlaceGuide> getFeatured({String? cityName, int limit = 2}) => const [];
}
