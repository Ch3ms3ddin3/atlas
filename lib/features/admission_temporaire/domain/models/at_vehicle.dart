/// Type de véhicule suivi pour l'admission temporaire.
enum AtVehicleType {
  car,
  motorcycle,
  camper,
  other,
}

extension AtVehicleTypeLabels on AtVehicleType {
  String get labelFr => switch (this) {
        AtVehicleType.car => 'Voiture',
        AtVehicleType.motorcycle => 'Moto',
        AtVehicleType.camper => 'Camping-car',
        AtVehicleType.other => 'Autre',
      };

  static AtVehicleType fromStorage(String? raw) {
    return AtVehicleType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AtVehicleType.car,
    );
  }
}

/// Statut d'échéance de l'admission temporaire.
enum AtUrgencyStatus {
  ok,
  warning,
  critical,
  expired,
}

/// Véhicule suivi localement (admission temporaire = propriété du véhicule).
///
/// Schéma prêt pour une sync Supabase future (`updatedAt`, `isActive`).
class AtVehicle {
  const AtVehicle({
    required this.id,
    required this.label,
    required this.plate,
    required this.countryCode,
    required this.countryLabel,
    required this.type,
    required this.entryDate,
    required this.expiryDate,
    required this.durationDays,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isActive = true,
    this.notificationSlot = 0,
  });

  final String id;
  final String label;
  final String plate;
  final String countryCode;
  final String countryLabel;
  final AtVehicleType type;

  /// Jour d'entrée sur le territoire (date seule, fuseau Casablanca).
  final DateTime entryDate;

  /// Fin de validité de l'admission temporaire.
  final DateTime expiryDate;

  /// Durée déclarée (jours) — base du calcul auto et de la barre de progression.
  final int durationDays;

  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tombstone pour sync future — false = supprimé.
  final bool isActive;

  /// Emplacement stable pour les IDs de notification (0–99).
  final int notificationSlot;

  AtVehicle copyWith({
    String? id,
    String? label,
    String? plate,
    String? countryCode,
    String? countryLabel,
    AtVehicleType? type,
    DateTime? entryDate,
    DateTime? expiryDate,
    int? durationDays,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? notificationSlot,
    bool clearNotes = false,
  }) {
    return AtVehicle(
      id: id ?? this.id,
      label: label ?? this.label,
      plate: plate ?? this.plate,
      countryCode: countryCode ?? this.countryCode,
      countryLabel: countryLabel ?? this.countryLabel,
      type: type ?? this.type,
      entryDate: entryDate ?? this.entryDate,
      expiryDate: expiryDate ?? this.expiryDate,
      durationDays: durationDays ?? this.durationDays,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      notificationSlot: notificationSlot ?? this.notificationSlot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'plate': plate,
      'countryCode': countryCode,
      'countryLabel': countryLabel,
      'type': type.name,
      'entryDate': _dateKey(entryDate),
      'expiryDate': _dateKey(expiryDate),
      'durationDays': durationDays,
      'notes': notes,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'isActive': isActive,
      'notificationSlot': notificationSlot,
    };
  }

  static AtVehicle? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final label = json['label'] as String?;
    final plate = json['plate'] as String?;
    final countryCode = json['countryCode'] as String?;
    final countryLabel = json['countryLabel'] as String?;
    final entryRaw = json['entryDate'] as String?;
    final expiryRaw = json['expiryDate'] as String?;
    final createdRaw = json['createdAt'] as String?;
    final updatedRaw = json['updatedAt'] as String?;
    final duration = json['durationDays'];

    if (id == null ||
        id.isEmpty ||
        label == null ||
        label.isEmpty ||
        plate == null ||
        plate.isEmpty ||
        countryCode == null ||
        countryCode.isEmpty ||
        countryLabel == null ||
        countryLabel.isEmpty ||
        entryRaw == null ||
        expiryRaw == null ||
        createdRaw == null ||
        updatedRaw == null ||
        duration is! num ||
        duration <= 0) {
      return null;
    }

    final entryDate = _parseDate(entryRaw);
    final expiryDate = _parseDate(expiryRaw);
    if (entryDate == null || expiryDate == null) return null;

    return AtVehicle(
      id: id,
      label: label,
      plate: plate,
      countryCode: countryCode,
      countryLabel: countryLabel,
      type: AtVehicleTypeLabels.fromStorage(json['type'] as String?),
      entryDate: entryDate,
      expiryDate: expiryDate,
      durationDays: duration.round(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(createdRaw).toUtc(),
      updatedAt: DateTime.parse(updatedRaw).toUtc(),
      isActive: json['isActive'] as bool? ?? true,
      notificationSlot: (json['notificationSlot'] as num?)?.round() ?? 0,
    );
  }

  static String _dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
