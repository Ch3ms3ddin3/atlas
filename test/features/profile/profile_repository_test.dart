import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/location/morocco_cities.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/data/profile_repository.dart';
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
  });

  group('ProfilePreferencesStore', () {
    test('renvoie les valeurs par défaut', () async {
      SharedPreferences.setMockInitialValues({});
      const store = ProfilePreferencesStore();

      final profile = await store.load();

      expect(profile.firstName, UserProfile.defaultFirstName);
      expect(profile.preferredCity, UserProfile.defaultPreferredCity);
      expect(profile.language, AtlasLanguage.french);
      expect(profile.userType, AtlasUserType.resident);
    });

    test('persiste et recharge le profil', () async {
      SharedPreferences.setMockInitialValues({});
      const store = ProfilePreferencesStore();

      const saved = UserProfile(
        firstName: 'Salma',
        preferredCity: 'Casablanca',
        language: AtlasLanguage.english,
        userType: AtlasUserType.visitor,
      );
      await store.save(saved);
      final profile = await store.load();

      expect(profile.firstName, 'Salma');
      expect(profile.preferredCity, 'Casablanca');
      expect(profile.language, AtlasLanguage.english);
      expect(profile.userType, AtlasUserType.visitor);
    });
  });

  group('ProfileRepository', () {
    test('notifie les écouteurs après enregistrement', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = ProfileRepository();
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
      final repository = ProfileRepository();
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
  });
}
