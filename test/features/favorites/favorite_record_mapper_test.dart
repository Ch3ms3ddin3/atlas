import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/favorites/data/favorite_record_mapper.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_record.dart';

void main() {
  group('FavoriteRecordMapper', () {
    test('convertit une ligne Supabase vers un FavoriteRecord', () {
      final record = FavoriteRecordMapper.fromRow({
        'entity_type': 'procedure',
        'entity_slug': 'procedure-renouveler-cin',
        'is_active': true,
        'updated_at': '2026-07-12T10:00:00.000Z',
      });

      expect(record.entityType, FavoriteEntityType.procedure);
      expect(record.entitySlug, 'procedure-renouveler-cin');
      expect(record.isActive, isTrue);
      expect(record.updatedAt, DateTime.utc(2026, 7, 12, 10));
    });

    test('convertit un FavoriteRecord vers une ligne Supabase', () {
      final row = FavoriteRecordMapper.toRow(
        userId: 'user-1',
        record: FavoriteRecord(
          entityType: FavoriteEntityType.price,
          entitySlug: 'price-taxi-marrakech',
          isActive: false,
          updatedAt: DateTime.utc(2026, 7, 12, 10),
        ),
      );

      expect(row['user_id'], 'user-1');
      expect(row['entity_type'], 'price');
      expect(row['entity_slug'], 'price-taxi-marrakech');
      expect(row['is_active'], isFalse);
      expect(row['updated_at'], '2026-07-12T10:00:00.000Z');
    });
  });
}
