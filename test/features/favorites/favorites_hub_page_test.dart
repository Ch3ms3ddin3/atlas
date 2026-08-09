import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/assistant/data/local_assistant_repository.dart';
import 'package:atlas/features/assistant/data/providers/mock_assistant_provider.dart';
import 'package:atlas/features/assistant/domain/models/assistant_context_snapshot.dart';
import 'package:atlas/features/assistant/presentation/assistant_scope.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/favorites/data/favorites_preferences_store.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/favorites/presentation/pages/favorites_page.dart';
import 'package:atlas/features/itineraries/data/syncing_itinerary_repository.dart';
import 'package:atlas/features/itineraries/presentation/itinerary_scope.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/presentation/pages/price_observation_detail_page.dart';
import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/domain/procedure_repository.dart';
import 'package:atlas/features/procedures/presentation/pages/procedure_detail_page.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';

import '../prices/price_intelligence_test_helpers.dart';

void _registerCatalogs() {
  PlaceRepository.resetForTest();
  ProcedureRepository.resetForTest();
  PriceIntelligenceRepository.resetForTest();
  PlaceRepository.registerFactory(LocalPlaceRepository.new);
  ProcedureRepository.registerFactory(LocalProcedureRepository.new);
  registerPriceIntelligenceFixtures();
}

Future<LocalFavoritesRepository> _loadedFavorites({
  Map<String, Object>? seed,
}) async {
  if (seed != null) {
    SharedPreferences.setMockInitialValues(seed);
  } else {
    SharedPreferences.setMockInitialValues({});
  }
  final repository = LocalFavoritesRepository();
  await repository.load();
  return repository;
}

Widget _hubApp(LocalFavoritesRepository favorites) {
  return MaterialApp(
    theme: AtlasTheme.light,
    home: FavoritesScope(repository: favorites, child: const FavoritesPage()),
  );
}

Widget _profileTree({
  required LocalFavoritesRepository favorites,
  required LocalProfileRepository profile,
  required LocalAtRepository at,
}) {
  return AuthScope(
    repository: _StubAuth(),
    child: ProfileScope(
      repository: profile,
      child: FavoritesScope(
        repository: favorites,
        child: AssistantScope(
          repository: LocalAssistantRepository(
            profileRepository: profile,
            authRepository: _StubAuth(),
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
          ),
          child: ItineraryScope(
            repository: SyncingItineraryRepository(
              favoritesRepository: favorites,
            ),
            child: const ProfilePage(),
          ),
        ),
      ),
    ),
  );
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
  Future<AuthActionResult> resetPassword({required String email}) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signOut() async => AuthActionResult.success();

  @override
  Future<AuthActionResult> deleteAccount() async => AuthActionResult.success();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetAtBootstrapForTests();
    _registerCatalogs();
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
    resetAtBootstrapForTests();
  });

  group('Favorites Hub empty / populated', () {
    testWidgets('shows honest empty state for all supported types', (
      tester,
    ) async {
      final favorites = await _loadedFavorites();
      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Aucun favori pour le moment'),
        findsOneWidget,
      );
      expect(find.textContaining('Aucun lieu en favori'), findsOneWidget);
      expect(find.textContaining('Aucune démarche en favori'), findsOneWidget);
      expect(
        find.textContaining('Aucun prix vérifié en favori'),
        findsOneWidget,
      );
    });

    testWidgets('shows populated place, procedure and price favorites', (
      tester,
    ) async {
      final favorites = await _loadedFavorites();
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
        entitySlug: 'sp95-marrakech',
      );

      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      expect(find.text('Jardin Majorelle'), findsOneWidget);
      expect(find.text('Renouveler la CIN'), findsOneWidget);
      expect(find.text('SP95 Marrakech'), findsOneWidget);
      expect(find.text('Lieux'), findsOneWidget);
      expect(find.text('Démarches'), findsOneWidget);
      expect(find.text('Prix vérifiés'), findsOneWidget);
      expect(find.textContaining('3 éléments sauvegardés'), findsOneWidget);
    });

    testWidgets('shows per-type empty lines when only one type is saved', (
      tester,
    ) async {
      final favorites = await _loadedFavorites();
      await favorites.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      );

      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      expect(find.text('Jardin Majorelle'), findsOneWidget);
      expect(find.text('Aucun lieu en favori.'), findsNothing);
      expect(find.text('Aucune démarche en favori.'), findsOneWidget);
      expect(find.text('Aucun prix vérifié en favori.'), findsOneWidget);
    });
  });

  group('Favorites Hub unfavorite / open / stale', () {
    testWidgets('removes a favorite from the hub toggle', (tester) async {
      final favorites = await _loadedFavorites();
      await favorites.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      );

      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      expect(find.text('Jardin Majorelle'), findsOneWidget);
      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pumpAndSettle();

      expect(favorites.activeFavorites, isEmpty);
      expect(
        find.textContaining('Aucun favori pour le moment'),
        findsOneWidget,
      );
    });

    testWidgets('opens resolvable place, procedure and price favorites', (
      tester,
    ) async {
      final favorites = await _loadedFavorites();
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
        entitySlug: 'sp95-marrakech',
      );

      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jardin Majorelle'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailPage), findsOneWidget);
      expect(find.text('Jardin Majorelle'), findsWidgets);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Renouveler la CIN'));
      await tester.pumpAndSettle();
      expect(find.byType(ProcedureDetailPage), findsOneWidget);
      expect(find.text('Renouveler la CIN'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('SP95 Marrakech'));
      await tester.pumpAndSettle();
      expect(find.byType(PriceObservationDetailPage), findsOneWidget);
      expect(find.text('SP95 Marrakech'), findsWidgets);
    });

    testWidgets('handles unresolved favorites honestly without crashing', (
      tester,
    ) async {
      final favorites = await _loadedFavorites();
      await favorites.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-stale-missing',
      );

      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      expect(find.text('Lieu indisponible'), findsOneWidget);
      expect(find.textContaining('place-stale-missing'), findsOneWidget);
      expect(
        find.text('Contenu non résolu — retirable uniquement.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Lieu indisponible'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Ce contenu n\'est plus disponible'),
        findsOneWidget,
      );
      expect(find.byType(PlaceDetailPage), findsNothing);

      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pumpAndSettle();
      expect(favorites.activeFavorites, isEmpty);
    });
  });

  group('Favorites Hub local / profile entry', () {
    testWidgets('loads local SharedPreferences favorites when logged out', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 8, 1).toIso8601String();
      final favorites = await _loadedFavorites(
        seed: {
          FavoritesPreferencesStore.recordsKey:
              '''
[
  {
    "entityType": "place",
    "entitySlug": "place-majorelle",
    "isActive": true,
    "updatedAt": "$now"
  }
]
''',
        },
      );

      expect(favorites.activeFavorites, hasLength(1));

      await tester.pumpWidget(_hubApp(favorites));
      await tester.pumpAndSettle();

      expect(find.text('Jardin Majorelle'), findsOneWidget);
    });

    testWidgets('Profile Favoris card opens the hub', (tester) async {
      final favorites = await _loadedFavorites();
      final profile = LocalProfileRepository();
      await profile.load();
      final at = LocalAtRepository();
      await at.load();
      ensureAtRepositoryForTests(repository: at);

      await tester.binding.setSurfaceSize(const Size(400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: _profileTree(favorites: favorites, profile: profile, at: at),
        ),
      );
      await tester.pumpAndSettle();

      final favoris = find.text('Favoris');
      await tester.ensureVisible(favoris);
      expect(favoris, findsOneWidget);
      await tester.tap(favoris);
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesPage), findsOneWidget);
      expect(find.text('Mes favoris'), findsOneWidget);
    });
  });

  group('Existing favorites behavior intact', () {
    testWidgets('detail toggle still adds and removes place favorite', (
      tester,
    ) async {
      final favorites = await _loadedFavorites();
      final place = LocalPlaceRepository().findById('place-majorelle')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: FavoritesScope(
            repository: favorites,
            child: PlaceDetailPage(place: place),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pump();
      expect(
        favorites.isFavorite(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-majorelle',
        ),
        isTrue,
      );

      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pump();
      expect(favorites.activeFavorites, isEmpty);
    });
  });
}
