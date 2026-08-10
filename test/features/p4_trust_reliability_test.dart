import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/presentation/at_scope.dart';
import 'package:atlas/features/assistant/data/local_assistant_repository.dart';
import 'package:atlas/features/assistant/data/providers/mock_assistant_provider.dart';
import 'package:atlas/features/assistant/domain/models/assistant_context_snapshot.dart';
import 'package:atlas/features/assistant/presentation/assistant_scope.dart';
import 'package:atlas/features/assistant/presentation/pages/assistant_page.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/events/data/local_event_repository.dart';
import 'package:atlas/features/events/domain/event_repository.dart';
import 'package:atlas/features/events/presentation/pages/events_calendar_page.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_featured_card.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_guide_card.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/itineraries/data/syncing_itinerary_repository.dart';
import 'package:atlas/features/itineraries/presentation/itinerary_scope.dart';
import 'package:atlas/features/itineraries/presentation/pages/trip_list_page.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/models/price_observation.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/presentation/widgets/price_intelligence_category_filter.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetAtBootstrapForTests();
    EventRepository.resetForTest();
    EventRepository.registerFactory(LocalEventRepository.new);
    PriceIntelligenceRepository.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(() {
    resetAtBootstrapForTests();
    EventRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
  });

  group('Explorer honesty', () {
    testWidgets('guide card has no invented star rating', (tester) async {
      final place = PlaceCatalog.guides.first;
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: FavoritesScope(
            repository: favorites,
            child: Scaffold(
              body: PlaceGuideCard(place: place, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('4.9'), findsNothing);
      expect(find.text('4.8'), findsNothing);
      expect(find.text('4.7'), findsNothing);
      expect(find.byIcon(Icons.near_me_outlined), findsNothing);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.textContaining(place.neighborhood), findsWidgets);
    });

    testWidgets('featured card has no invented star rating', (tester) async {
      final place = PlaceCatalog.guides.firstWhere((p) => p.isEditorsPick);
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: FavoritesScope(
            repository: favorites,
            child: Scaffold(
              body: SingleChildScrollView(
                child: PlaceFeaturedCard(place: place, onTap: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('4.9'), findsNothing);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    });
  });

  group('Prices honesty', () {
    test('Wave 1 catalog categories exclude fuel and groceries', () {
      final categories = PriceObservationCatalog.entries
          .map((e) => e.category)
          .toSet();
      expect(categories.contains(PriceIntelligenceCategory.fuel), isFalse);
      expect(
        categories.contains(PriceIntelligenceCategory.supermarkets),
        isFalse,
      );
      expect(
        categories.contains(PriceIntelligenceCategory.publicTransport),
        isTrue,
      );
      expect(categories.contains(PriceIntelligenceCategory.parking), isTrue);
      expect(
        categories.contains(PriceIntelligenceCategory.mobilePlans),
        isTrue,
      );
      expect(categories.contains(PriceIntelligenceCategory.internet), isTrue);
    });

    testWidgets('category filter only shows available categories', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(
            body: PriceIntelligenceCategoryFilter(
              selectedCategory: null,
              availableCategories: const [
                PriceIntelligenceCategory.publicTransport,
                PriceIntelligenceCategory.parking,
              ],
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Transport public'), findsOneWidget);
      expect(find.text('Parking'), findsOneWidget);
      expect(find.text('Carburant'), findsNothing);
      expect(find.text('Supermarchés'), findsNothing);
      expect(find.text('Taxi'), findsNothing);
    });

    test('resilient repo categories reflect loaded inventory only', () async {
      final observations = PriceObservationCatalog.asObservations;
      final repo = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => observations,
      );
      await repo.warmUp();
      final cats = repo.categories.toSet();
      expect(cats.contains(PriceIntelligenceCategory.fuel), isFalse);
      expect(cats.contains(PriceIntelligenceCategory.supermarkets), isFalse);
      expect(cats, isNotEmpty);
    });
  });

  group('Profile route reliability', () {
    testWidgets('open Assistant outside shell scopes without exception', (
      tester,
    ) async {
      final profile = LocalProfileRepository();
      await profile.load();
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final at = LocalAtRepository();
      await at.load();
      final auth = _StubAuth();
      final assistant = LocalAssistantRepository(
        profileRepository: profile,
        authRepository: auth,
        favoritesRepository: favorites,
        atRepository: at,
        provider: MockAssistantProvider(chunkDelay: Duration.zero),
        contextProvider: () async => const AssistantContextSnapshot(
          city: 'Marrakech',
          userType: 'resident',
          language: 'french',
          authKind: 'unavailable',
          isSignedIn: false,
        ),
      );
      await assistant.load();
      final itinerary = SyncingItineraryRepository(
        favoritesRepository: favorites,
      );

      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Production-like: scopes under home only, not wrapping MaterialApp.
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: AuthScope(
            repository: auth,
            child: ProfileScope(
              repository: profile,
              child: FavoritesScope(
                repository: favorites,
                child: AtScope(
                  repository: at,
                  child: AssistantScope(
                    repository: assistant,
                    child: ItineraryScope(
                      repository: itinerary,
                      child: ShellNavigationScope(
                        navigateToTab: (_) {},
                        child: Builder(
                          builder: (context) {
                            return Scaffold(
                              body: TextButton(
                                onPressed: () => AssistantPage.open(context),
                                child: const Text('Open Assistant'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Assistant'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Assistant Atlas'), findsWidgets);
    });

    testWidgets('open Itineraries outside shell scopes without exception', (
      tester,
    ) async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final itinerary = SyncingItineraryRepository(
        favoritesRepository: favorites,
      );

      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: ItineraryScope(
            repository: itinerary,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => TripListPage.open(context),
                    child: const Text('Open Trips'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Trips'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Itinéraires'), findsOneWidget);
    });
  });

  group('Events honesty', () {
    testWidgets('agenda frames national holidays and hides empty categories', (
      tester,
    ) async {
      EventRepository.registerFactory(
        () => LocalEventRepository(nowProvider: () => DateTime(2026, 7, 17)),
      );

      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(theme: AtlasTheme.light, home: const EventsCalendarPage()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('pas un calendrier festivals complet'),
        findsWidgets,
      );
      expect(find.text('Festivals culturels'), findsNothing);
      expect(find.text('Sport'), findsNothing);
      expect(find.text('Vacances scolaires'), findsNothing);
      // Single category inventory → category chips hidden.
      expect(find.text('Catégorie'), findsNothing);
      expect(find.text('Jours fériés'), findsNothing);
    });
  });
}

class _StubAuth extends AuthRepository {
  _StubAuth() : super.base();

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
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async => AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithApple() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithGoogle() async =>
      AuthActionResult.success();


  @override
  bool get isPasswordRecoveryPending => false;

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
  Future<AuthActionResult> resetPassword({required String email}) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signOut() async => AuthActionResult.success();

  @override
  Future<AuthActionResult> deleteAccount() async => AuthActionResult.success();
}
