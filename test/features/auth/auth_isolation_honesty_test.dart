import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/auth/data/local_user_data_isolator.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/auth/presentation/auth_isolation_copy.dart';
import 'package:atlas/features/auth/presentation/auth_scope.dart';
import 'package:atlas/features/auth/presentation/widgets/profile_account_section.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/favorites/data/favorites_preferences_store.dart';
import 'package:atlas/features/favorites/data/syncing_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_record.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthIsolationCopy honesty', () {
    test('sign-out copy keeps cloud, clears local wording', () {
      expect(AuthIsolationCopy.signOutBody, contains('n’est pas supprimé'));
      expect(AuthIsolationCopy.signOutBody, contains('effacées'));
      expect(AuthIsolationCopy.signOutBody, contains('cloud'));
      expect(AuthIsolationCopy.signOutBody, isNot(contains('conservées')));
      expect(AuthIsolationCopy.signOutSuccess, contains('effacées'));
      expect(
        AuthIsolationCopy.signOutSuccess,
        isNot(contains('conservées')),
      );
    });

    test('delete-account copy clears cloud and local', () {
      expect(AuthIsolationCopy.deleteAccountBody, contains('définitive'));
      expect(AuthIsolationCopy.deleteAccountBody, contains('cloud'));
      expect(AuthIsolationCopy.deleteAccountBody, contains('locales'));
      expect(
        AuthIsolationCopy.deleteAccountBody,
        isNot(contains('restent sur cet appareil')),
      );
      expect(AuthIsolationCopy.deleteAccountSuccess, contains('effacées'));
      expect(
        AuthIsolationCopy.deleteAccountSuccess,
        isNot(contains('conservé')),
      );
    });
  });

  group('AppShell-equivalent identity boundary', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'signedIn → anonymous : clear puis reload = profil/favoris neutres',
      () async {
        const profileStore = ProfilePreferencesStore();
        await profileStore.saveProfile(
          const UserProfile(
            firstName: 'Alice',
            preferredCity: 'Casablanca',
            language: AtlasLanguage.french,
            userType: AtlasUserType.mre,
            displayName: 'Alice Cloud',
            avatarUrl: 'https://cdn.example/a.png',
          ),
          localUpdatedAt: DateTime.utc(2026, 8, 11),
        );

        const favoritesStore = FavoritesPreferencesStore();
        await favoritesStore.saveRecords([
          FavoriteRecord(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
            isActive: true,
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        ]);

        expect(
          LocalUserDataIsolator.shouldClearLocal(
            previousKind: AuthSessionKind.signedIn,
            previousUserId: 'user-a',
            nextKind: AuthSessionKind.anonymous,
            nextUserId: 'anon-after-logout',
          ),
          isTrue,
        );

        await LocalUserDataIsolator.clearPersistedUserData();

        final profile = LocalProfileRepository(store: profileStore);
        await profile.load();
        expect(profile.profile.firstName, UserProfile.defaultFirstName);
        expect(
          profile.profile.preferredCity,
          UserProfile.defaultPreferredCity,
        );
        expect(profile.profile.displayName, isNull);
        expect(profile.profile.avatarUrl, isNull);

        final favorites = SyncingFavoritesRepository(store: favoritesStore);
        await favorites.load();
        expect(
          favorites.isFavorite(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
          ),
          isFalse,
        );
      },
    );

    test(
      'anonymous guest blob ne traverse pas un login signedIn',
      () async {
        const profileStore = ProfilePreferencesStore();
        await profileStore.saveProfile(
          const UserProfile(
            firstName: 'Guest',
            preferredCity: 'Rabat',
            language: AtlasLanguage.french,
            userType: AtlasUserType.tourist,
          ),
          localUpdatedAt: DateTime.utc(2026, 8, 11),
        );

        expect(
          LocalUserDataIsolator.shouldClearLocal(
            previousKind: AuthSessionKind.anonymous,
            previousUserId: 'anon-1',
            nextKind: AuthSessionKind.signedIn,
            nextUserId: 'user-a',
          ),
          isTrue,
        );

        await LocalUserDataIsolator.clearPersistedUserData();

        final profile = LocalProfileRepository(store: profileStore);
        await profile.load();
        expect(profile.profile.firstName, isNot('Guest'));
        expect(profile.profile.firstName, UserProfile.defaultFirstName);
        expect(profile.profile.preferredCity, isNot('Rabat'));
      },
    );

    test('switch compte A → B : clear obligatoire', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: AuthSessionKind.signedIn,
          previousUserId: 'user-a',
          nextKind: AuthSessionKind.signedIn,
          nextUserId: 'user-b',
        ),
        isTrue,
      );
    });
  });

  group('ProfileAccountSection sign-out honesty', () {
    testWidgets('footer signed-in annonce l\'effacement local', (tester) async {
      final repository = _ControllableAuthRepository(
        session: const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-a',
          email: 'alice@example.com',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: repository,
            child: const Scaffold(body: ProfileAccountSection()),
          ),
        ),
      );

      expect(find.text(AuthIsolationCopy.signedInFooter), findsOneWidget);
      expect(find.textContaining('données locales conservées'), findsNothing);
    });

    testWidgets('Annuler sur le dialogue n\'appelle pas signOut', (
      tester,
    ) async {
      final repository = _ControllableAuthRepository(
        session: const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-a',
          email: 'alice@example.com',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: repository,
            child: const Scaffold(body: ProfileAccountSection()),
          ),
        ),
      );

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.text(AuthIsolationCopy.signOutTitle), findsOneWidget);
      expect(find.text(AuthIsolationCopy.signOutBody), findsOneWidget);
      expect(
        find.textContaining('n’est pas supprimé'),
        findsOneWidget,
      );

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(repository.signOutCalls, 0);
    });

    testWidgets('Confirmer affiche le snackbar d\'effacement local', (
      tester,
    ) async {
      final repository = _ControllableAuthRepository(
        session: const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-a',
          email: 'alice@example.com',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            repository: repository,
            child: const Scaffold(body: ProfileAccountSection()),
          ),
        ),
      );

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, AuthIsolationCopy.signOutConfirm),
      );
      await tester.pumpAndSettle();

      expect(repository.signOutCalls, 1);
      expect(find.text(AuthIsolationCopy.signOutSuccess), findsOneWidget);
      // Guest footer may say « conservées » after logout — that is honest for
      // anonymous. The signed-in lie must not remain.
      expect(find.text(AuthIsolationCopy.signedInFooter), findsNothing);
      expect(
        find.textContaining('Déconnecté — vos données locales sont conservées'),
        findsNothing,
      );
      expect(
        find.textContaining('Déconnecté — données locales conservées'),
        findsNothing,
      );
    });
  });
}

class _ControllableAuthRepository extends AuthRepository {
  _ControllableAuthRepository({required this.session}) : super.base();

  @override
  AuthSession session;
  int signOutCalls = 0;

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
    signOutCalls += 1;
    session = const AuthSession(
      kind: AuthSessionKind.anonymous,
      userId: 'anon-after',
    );
    notifyListeners();
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async {
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
  Future<AuthActionResult> resetPassword({required String email}) async {
    return AuthActionResult.success();
  }

  @override
  Future<AuthActionResult> deleteAccount() async {
    return AuthActionResult.success();
  }
}
