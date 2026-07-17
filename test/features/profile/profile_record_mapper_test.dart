import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/profile/data/profile_record_mapper.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  group('ProfileRecordMapper', () {
    test('mappe une ligne Supabase vers un profil distant', () {
      final snapshot = ProfileRecordMapper.fromRow({
        'first_name': 'Salma',
        'preferred_city': 'Casablanca',
        'language': 'english',
        'user_type': 'visitor',
        'display_name': 'Salma Benali',
        'avatar_url': 'https://example.com/a.png',
        'updated_at': '2026-07-12T10:00:00.000Z',
      });

      expect(snapshot.profile.firstName, 'Salma');
      expect(snapshot.profile.preferredCity, 'Casablanca');
      expect(snapshot.profile.language, AtlasLanguage.english);
      expect(snapshot.profile.userType, AtlasUserType.tourist);
      expect(snapshot.profile.displayName, 'Salma Benali');
      expect(snapshot.profile.avatarUrl, 'https://example.com/a.png');
      expect(snapshot.updatedAt, DateTime.utc(2026, 7, 12, 10));
    });

    test('sérialise un profil pour upsert', () {
      const profile = UserProfile(
        firstName: 'Yasmine',
        preferredCity: 'Rabat',
        language: AtlasLanguage.french,
        userType: AtlasUserType.mre,
        displayName: 'Yasmine M.',
        avatarUrl: 'https://cdn.example/y.png',
      );

      final row = ProfileRecordMapper.toRow(
        userId: 'user-123',
        profile: profile,
      );

      expect(row['id'], 'user-123');
      expect(row['first_name'], 'Yasmine');
      expect(row['preferred_city'], 'Rabat');
      expect(row['language'], 'french');
      expect(row['user_type'], 'mre');
      expect(row['display_name'], 'Yasmine M.');
      expect(row['avatar_url'], 'https://cdn.example/y.png');
    });
  });
}
