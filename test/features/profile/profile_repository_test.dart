import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/location/morocco_cities.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/data/profile_validator.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  group('ProfileValidator', () {
    test('rejette un prénom vide', () {
      expect(
        ProfileValidator.validateFirstName('   ')?.message,
        'Le prénom est requis.',
      );
    });

    test('accepte un prénom valide', () {
      expect(ProfileValidator.validateFirstName('Chemseddine'), isNull);
    });

    test('rejette une ville inconnue', () {
      expect(
        ProfileValidator.validatePreferredCity('Paris')?.message,
        'Ville non reconnue.',
      );
    });

    test('accepte les six villes du MVP', () {
      for (final city in MoroccoCities.supportedNames) {
        expect(ProfileValidator.validatePreferredCity(city), isNull);
      }
    });

    test('sanitizeForSave conserve displayName et avatarUrl', () {
      const candidate = UserProfile(
        firstName: '  Salma  ',
        preferredCity: 'casablanca',
        language: AtlasLanguage.french,
        userType: AtlasUserType.resident,
        displayName: '  Salma Benali  ',
        avatarUrl: ' https://cdn.example/a.png ',
      );

      final sanitized = ProfileValidator.sanitizeForSave(candidate);

      expect(sanitized, isNotNull);
      expect(sanitized!.firstName, 'Salma');
      expect(sanitized.preferredCity, 'Casablanca');
      expect(sanitized.displayName, 'Salma Benali');
      expect(sanitized.avatarUrl, 'https://cdn.example/a.png');
    });

    test(
      'sanitizeForSave normalise les identité optionnelles vides en null',
      () {
        const candidate = UserProfile(
          firstName: 'Salma',
          preferredCity: 'Marrakech',
          language: AtlasLanguage.french,
          userType: AtlasUserType.resident,
          displayName: '   ',
          avatarUrl: '',
        );

        final sanitized = ProfileValidator.sanitizeForSave(candidate);

        expect(sanitized, isNotNull);
        expect(sanitized!.displayName, isNull);
        expect(sanitized.avatarUrl, isNull);
      },
    );

    test(
      'sanitizeForSave refuse un prénom invalide sans inventer d\'identité',
      () {
        const candidate = UserProfile(
          firstName: '   ',
          preferredCity: 'Marrakech',
          language: AtlasLanguage.french,
          userType: AtlasUserType.resident,
          displayName: 'Should not persist',
          avatarUrl: 'https://cdn.example/a.png',
        );

        expect(ProfileValidator.sanitizeForSave(candidate), isNull);
      },
    );
  });

  group('ProfilePreferencesStore', () {
    test('renvoie les valeurs par défaut', () async {
      SharedPreferences.setMockInitialValues({});
      const store = ProfilePreferencesStore();

      final snapshot = await store.loadSnapshot();

      expect(snapshot.profile.firstName, UserProfile.defaultFirstName);
      expect(snapshot.profile.preferredCity, UserProfile.defaultPreferredCity);
      expect(snapshot.profile.language, AtlasLanguage.french);
      expect(snapshot.profile.userType, AtlasUserType.resident);
      expect(snapshot.localUpdatedAt, isNull);
      expect(snapshot.syncPending, isFalse);
    });

    test('persiste le profil et les métadonnées de synchronisation', () async {
      SharedPreferences.setMockInitialValues({});
      const store = ProfilePreferencesStore();
      final updatedAt = DateTime.utc(2026, 7, 12, 9);

      const saved = UserProfile(
        firstName: 'Salma',
        preferredCity: 'Casablanca',
        language: AtlasLanguage.english,
        userType: AtlasUserType.tourist,
      );
      await store.saveProfile(saved, localUpdatedAt: updatedAt);
      await store.setSyncPending(true);
      final snapshot = await store.loadSnapshot();

      expect(snapshot.profile.firstName, 'Salma');
      expect(snapshot.profile.preferredCity, 'Casablanca');
      expect(snapshot.profile.language, AtlasLanguage.english);
      expect(snapshot.profile.userType, AtlasUserType.tourist);
      expect(snapshot.localUpdatedAt, updatedAt);
      expect(snapshot.syncPending, isTrue);
    });
  });

  group('LocalProfileRepository', () {
    test('notifie les écouteurs après enregistrement', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalProfileRepository();
      var notifications = 0;
      repository.addListener(() => notifications++);

      await repository.load();
      final saved = await repository.save(
        const UserProfile(
          firstName: 'Yasmine',
          preferredCity: 'Rabat',
          language: AtlasLanguage.french,
          userType: AtlasUserType.mre,
        ),
      );

      expect(saved, isTrue);
      expect(repository.profile.firstName, 'Yasmine');
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('refuse un profil invalide', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalProfileRepository();
      await repository.load();

      final saved = await repository.save(
        const UserProfile(
          firstName: '   ',
          preferredCity: 'Marrakech',
          language: AtlasLanguage.french,
          userType: AtlasUserType.resident,
        ),
      );

      expect(saved, isFalse);
      expect(repository.profile.firstName, UserProfile.defaultFirstName);
    });

    test('préserve displayName et avatarUrl après save', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalProfileRepository();
      await repository.load();

      final saved = await repository.save(
        const UserProfile(
          firstName: 'Yasmine',
          preferredCity: 'Rabat',
          language: AtlasLanguage.french,
          userType: AtlasUserType.mre,
          displayName: 'Yasmine M.',
          avatarUrl: 'https://cdn.example/y.png',
        ),
      );

      expect(saved, isTrue);
      expect(repository.profile.displayName, 'Yasmine M.');
      expect(repository.profile.avatarUrl, 'https://cdn.example/y.png');

      // ProfilePage-style edit: copyWith required fields only.
      final edited = await repository.save(
        repository.profile.copyWith(
          firstName: 'Yasmine',
          preferredCity: 'Casablanca',
        ),
      );

      expect(edited, isTrue);
      expect(repository.profile.firstName, 'Yasmine');
      expect(repository.profile.preferredCity, 'Casablanca');
      expect(repository.profile.displayName, 'Yasmine M.');
      expect(repository.profile.avatarUrl, 'https://cdn.example/y.png');

      final store = ProfilePreferencesStore();
      final snapshot = await store.loadSnapshot();
      expect(snapshot.profile.displayName, 'Yasmine M.');
      expect(snapshot.profile.avatarUrl, 'https://cdn.example/y.png');
      expect(snapshot.profile.preferredCity, 'Casablanca');

      // Reload path — city must survive app restart.
      final reloaded = LocalProfileRepository();
      await reloaded.load();
      expect(reloaded.profile.preferredCity, 'Casablanca');
      expect(reloaded.profile.firstName, 'Yasmine');
      expect(reloaded.profile.displayName, 'Yasmine M.');
      expect(reloaded.profile.avatarUrl, 'https://cdn.example/y.png');
    });

    test('sanitize ne vide pas les champs non liés', () {
      const candidate = UserProfile(
        firstName: 'Nour',
        preferredCity: 'Tanger',
        language: AtlasLanguage.french,
        userType: AtlasUserType.tourist,
        displayName: 'Nour Atlas',
        avatarUrl: 'https://cdn.example/n.png',
      );

      final sanitized = ProfileValidator.sanitizeForSave(
        candidate.copyWith(preferredCity: 'Agadir'),
      );

      expect(sanitized, isNotNull);
      expect(sanitized!.preferredCity, 'Agadir');
      expect(sanitized.firstName, 'Nour');
      expect(sanitized.displayName, 'Nour Atlas');
      expect(sanitized.avatarUrl, 'https://cdn.example/n.png');
      expect(sanitized.language, AtlasLanguage.french);
      expect(sanitized.userType, AtlasUserType.tourist);
    });
  });
}
