import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/at_vehicle.dart';

class SupabaseAtRepository {
  const SupabaseAtRepository();

  SupabaseClient? get _client => SupabaseBootstrap.clientOrNull();

  Future<List<AtVehicle>?> fetchAll(String userId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final rows = await client
          .from('at_vehicles')
          .select()
          .eq('user_id', userId);
      return rows
          .map((row) => fromRow(Map<String, dynamic>.from(row as Map)))
          .whereType<AtVehicle>()
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<bool> upsertAll({
    required String userId,
    required List<AtVehicle> vehicles,
  }) async {
    final client = _client;
    if (client == null) return false;
    try {
      final payload = vehicles
          .map((v) => toRow(userId: userId, vehicle: v))
          .toList(growable: false);
      if (payload.isEmpty) return true;
      await client.from('at_vehicles').upsert(payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> toRow({
    required String userId,
    required AtVehicle vehicle,
  }) {
    return {
      'id': vehicle.id,
      'user_id': userId,
      'label': vehicle.label,
      'plate': vehicle.plate,
      'country_code': vehicle.countryCode,
      'country_label': vehicle.countryLabel,
      'vehicle_type': vehicle.type.name,
      'entry_date': _dateOnly(vehicle.entryDate),
      'expiry_date': _dateOnly(vehicle.expiryDate),
      'duration_days': vehicle.durationDays,
      'notes': vehicle.notes,
      'notification_slot': vehicle.notificationSlot,
      'is_active': vehicle.isActive,
      'created_at': vehicle.createdAt.toUtc().toIso8601String(),
      'updated_at': vehicle.updatedAt.toUtc().toIso8601String(),
    };
  }

  static AtVehicle? fromRow(Map<String, dynamic> row) {
    try {
      return AtVehicle(
        id: row['id'] as String,
        label: row['label'] as String,
        plate: row['plate'] as String,
        countryCode: row['country_code'] as String,
        countryLabel: row['country_label'] as String,
        type: AtVehicleTypeLabels.fromStorage(row['vehicle_type'] as String?),
        entryDate: DateTime.parse(row['entry_date'] as String),
        expiryDate: DateTime.parse(row['expiry_date'] as String),
        durationDays: row['duration_days'] as int,
        notes: row['notes'] as String?,
        notificationSlot: row['notification_slot'] as int? ?? 0,
        isActive: row['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
        updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _dateOnly(DateTime value) {
    final d = DateTime(value.year, value.month, value.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
