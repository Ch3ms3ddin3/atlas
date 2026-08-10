import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/at_calculator.dart';
import 'package:atlas/features/admission_temporaire/data/at_guidance.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/domain/models/at_vehicle.dart';
import 'package:atlas/features/admission_temporaire/presentation/at_scope.dart';
import 'package:atlas/features/admission_temporaire/presentation/pages/at_tracker_page.dart';
import 'package:atlas/features/events/data/local_event_repository.dart';
import 'package:atlas/features/events/domain/event_repository.dart';
import 'package:atlas/features/events/presentation/pages/events_calendar_page.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/assistant/data/local_assistant_repository.dart';
import 'package:atlas/features/assistant/data/providers/mock_assistant_provider.dart';
import 'package:atlas/features/assistant/domain/models/assistant_context_snapshot.dart';
import 'package:atlas/features/assistant/presentation/assistant_scope.dart';
import 'package:atlas/features/itineraries/data/syncing_itinerary_repository.dart';
import 'package:atlas/features/itineraries/presentation/itinerary_scope.dart';

AtVehicle _vehicle({
  required int remainingDays,
  int durationDays = 180,
  String? notes,
  String id = 'v-test',
}) {
  final now = AtCalculator.calendarDay(AtCalculator.casablancaNow());
  final expiry = now.add(Duration(days: remainingDays));
  final entry = expiry.subtract(Duration(days: durationDays));
  final stamp = DateTime.now().toUtc();
  return AtVehicle(
    id: id,
    label: 'TestCar',
    plate: 'AA-000-AA',
    countryCode: 'FR',
    countryLabel: 'France',
    type: AtVehicleType.car,
    entryDate: entry,
    expiryDate: expiry,
    durationDays: durationDays,
    notes: notes,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

/// Mimics production: AtScope under home only (inside shell), not above MaterialApp.
Widget _productionLikeShell({
  required LocalAtRepository at,
  required Widget home,
}) {
  return MaterialApp(
    theme: AtlasTheme.light,
    home: AtScope(repository: at, child: home),
  );
}

Widget _profileTree({
  required LocalAtRepository at,
  required LocalProfileRepository profile,
  required LocalFavoritesRepository favorites,
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
  });

  tearDown(() {
    resetAtBootstrapForTests();
    EventRepository.resetForTest();
  });

  group('AtGuidance / boundaries', () {
    test('status boundaries match warning and critical windows', () {
      final now = AtCalculator.calendarDay(AtCalculator.casablancaNow());
      expect(
        AtCalculator.status(expiryDate: now.add(const Duration(days: 31))),
        AtUrgencyStatus.ok,
      );
      expect(
        AtCalculator.status(expiryDate: now.add(const Duration(days: 30))),
        AtUrgencyStatus.warning,
      );
      expect(
        AtCalculator.status(expiryDate: now.add(const Duration(days: 8))),
        AtUrgencyStatus.warning,
      );
      expect(
        AtCalculator.status(expiryDate: now.add(const Duration(days: 7))),
        AtUrgencyStatus.critical,
      );
      expect(AtCalculator.status(expiryDate: now), AtUrgencyStatus.critical);
      expect(
        AtCalculator.status(expiryDate: now.subtract(const Duration(days: 1))),
        AtUrgencyStatus.expired,
      );
    });

    test('next actions remain non-legal and status-specific', () {
      expect(
        AtGuidance.nextActionFor(AtUrgencyStatus.ok),
        contains('Surveillez'),
      );
      expect(
        AtGuidance.nextActionFor(AtUrgencyStatus.expired),
        contains('douane'),
      );
      expect(AtGuidance.eligibilityBullets, isNotEmpty);
      expect(AtGuidance.officialSourceUrl, contains('douane.gov.ma'));
    });

    test('remaining days is deterministic for fixed expiry', () {
      final now = DateTime(2026, 8, 9);
      final expiry = DateTime(2026, 8, 19);
      expect(AtCalculator.remainingDays(expiryDate: expiry, now: now), 10);
    });
  });

  group('Profile → AT empty (P2 regression)', () {
    testWidgets(
      'Profil → AT sans données rend l\'état vide sans exception',
      (tester) async {
        final profile = LocalProfileRepository();
        await profile.load();
        final favorites = LocalFavoritesRepository();
        await favorites.load();
        final at = LocalAtRepository();
        await at.load();
        ensureAtRepositoryForTests(repository: at);
        expect(at.activeVehicles, isEmpty);

        await tester.binding.setSurfaceSize(const Size(400, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Production-like tree: AtScope ONLY under home (not wrapping MaterialApp).
        await tester.pumpWidget(
          _productionLikeShell(
            at: at,
            home: _profileTree(
              at: at,
              profile: profile,
              favorites: favorites,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text('Véhicules / Admission temporaire'),
        );
        await tester.tap(find.text('Véhicules / Admission temporaire'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Mes véhicules au Maroc'), findsOneWidget);
        expect(find.text('Aucun véhicule suivi'), findsOneWidget);
        expect(find.text('Ajouter un véhicule'), findsOneWidget);
        expect(find.textContaining('Cadre & règles'), findsOneWidget);
      },
    );

    testWidgets('Profil expose AT et Agenda', (tester) async {
      final profile = LocalProfileRepository();
      await profile.load();
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final at = LocalAtRepository();
      await at.load();
      ensureAtRepositoryForTests(repository: at);

      await tester.binding.setSurfaceSize(const Size(400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _productionLikeShell(
          at: at,
          home: _profileTree(
            at: at,
            profile: profile,
            favorites: favorites,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Véhicules / Admission temporaire'), findsOneWidget);
      expect(find.text('Agenda Maroc'), findsOneWidget);

      await tester.ensureVisible(find.text('Véhicules / Admission temporaire'));
      await tester.tap(find.text('Véhicules / Admission temporaire'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Mes véhicules au Maroc'), findsOneWidget);
      expect(find.textContaining('Cadre & règles'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Agenda Maroc'));
      await tester.tap(find.text('Agenda Maroc'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Agenda'), findsWidgets);
    });
  });

  group('AT tracker P2', () {
    testWidgets('empty tracker onboarding without exception', (tester) async {
      final repository = LocalAtRepository();
      await repository.load();
      ensureAtRepositoryForTests(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: AtScope(
            repository: repository,
            child: const AtTrackerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Aucun véhicule suivi'), findsOneWidget);
      expect(find.text('Ajouter un véhicule'), findsOneWidget);
    });

    testWidgets('partial AT data (notes null) renders without exception', (
      tester,
    ) async {
      final repository = LocalAtRepository();
      await repository.load();
      await repository.addVehicle(
        _vehicle(remainingDays: 45, notes: null, id: 'partial'),
      );
      ensureAtRepositoryForTests(repository: repository);

      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: AtScope(repository: repository, child: const AtTrackerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dates déclarées (saisie utilisateur)'), findsOneWidget);
      expect(find.text('Notes (saisie utilisateur)'), findsNothing);
      expect(find.text('Prochaine action'), findsOneWidget);
    });

    testWidgets('tracker peuplé montre dates déclarées et prochaine action', (
      tester,
    ) async {
      final repository = LocalAtRepository();
      await repository.load();
      await repository.addVehicle(
        _vehicle(remainingDays: 12, notes: 'Caution déposée'),
      );
      ensureAtRepositoryForTests(repository: repository);

      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: AtScope(repository: repository, child: const AtTrackerPage()),
        ),
      );
      await tester.pumpAndSettle();

      final declared = find.text('Dates déclarées (saisie utilisateur)');
      await tester.scrollUntilVisible(declared, 300);
      expect(declared, findsOneWidget);

      final next = find.text('Prochaine action');
      await tester.scrollUntilVisible(next, 200);
      expect(next, findsOneWidget);

      expect(find.textContaining('aucune validation douanière'), findsWidgets);
      expect(find.text('Notes (saisie utilisateur)'), findsOneWidget);
      expect(find.text('Caution déposée'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Guide Admission temporaire'),
        300,
      );
      expect(find.text('Guide Admission temporaire'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Rappels d\'échéance'), 400);
      expect(find.text('Rappels d\'échéance'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    });

    testWidgets('expired vehicle shows expired status without exception', (
      tester,
    ) async {
      final repository = LocalAtRepository();
      await repository.load();
      await repository.addVehicle(_vehicle(remainingDays: -3, id: 'expired'));
      ensureAtRepositoryForTests(repository: repository);

      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: AtScope(repository: repository, child: const AtTrackerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Expiré'), findsWidgets);
      expect(find.textContaining('Expiré depuis'), findsWidgets);
      expect(find.textContaining('période que vous avez déclarée'), findsOneWidget);
    });

    testWidgets('reminder switch stays off by default', (tester) async {
      final repository = LocalAtRepository();
      await repository.load();
      await repository.addVehicle(_vehicle(remainingDays: 20));
      ensureAtRepositoryForTests(repository: repository);
      expect(repository.notificationsEnabled, isFalse);

      await tester.binding.setSurfaceSize(const Size(400, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: AtScope(repository: repository, child: const AtTrackerPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Rappels d\'échéance'), 400);
      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    });

    testWidgets(
      'openVehiclesTracker wraps AtScope when pushed outside shell',
      (tester) async {
        final repository = LocalAtRepository();
        await repository.load();
        ensureAtRepositoryForTests(repository: repository);

        await tester.pumpWidget(
          _productionLikeShell(
            at: repository,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => openVehiclesTracker(context),
                    child: const Text('Open AT'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open AT'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Aucun véhicule suivi'), findsOneWidget);
      },
    );
  });

  group('Events empty honesty', () {
    testWidgets('calendrier rappelle qu\'aucun contenu n\'est inventé', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AtlasTheme.light, home: const EventsCalendarPage()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('jamais inventées'), findsOneWidget);
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
