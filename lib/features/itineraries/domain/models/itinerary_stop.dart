import 'itinerary_enums.dart';

/// Arrêt ordonné d'une journée.
class ItineraryStop {
  const ItineraryStop({
    required this.id,
    required this.type,
    required this.title,
    required this.source,
    this.refId,
    this.latitude,
    this.longitude,
    this.startTime,
    this.endTime,
    this.estimatedDurationMin,
    this.travelFromPreviousMin,
    this.travelDistanceKm,
    this.budgetMad,
    this.notes,
    this.externalUrl,
    this.bookingHint,
  });

  final String id;
  final ItineraryStopType type;
  final String title;
  final ItineraryStopSource source;
  final String? refId;
  final double? latitude;
  final double? longitude;
  final String? startTime;
  final String? endTime;
  final int? estimatedDurationMin;
  final int? travelFromPreviousMin;
  final double? travelDistanceKm;
  final double? budgetMad;
  final String? notes;
  final String? externalUrl;

  /// Réservé aux futurs providers de réservation.
  final String? bookingHint;

  bool get hasCoordinates => latitude != null && longitude != null;

  ItineraryStop copyWith({
    String? title,
    ItineraryStopType? type,
    ItineraryStopSource? source,
    String? refId,
    double? latitude,
    double? longitude,
    String? startTime,
    String? endTime,
    int? estimatedDurationMin,
    int? travelFromPreviousMin,
    double? travelDistanceKm,
    double? budgetMad,
    String? notes,
    String? externalUrl,
    String? bookingHint,
    bool clearTravel = false,
  }) {
    return ItineraryStop(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      source: source ?? this.source,
      refId: refId ?? this.refId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedDurationMin: estimatedDurationMin ?? this.estimatedDurationMin,
      travelFromPreviousMin: clearTravel
          ? null
          : (travelFromPreviousMin ?? this.travelFromPreviousMin),
      travelDistanceKm:
          clearTravel ? null : (travelDistanceKm ?? this.travelDistanceKm),
      budgetMad: budgetMad ?? this.budgetMad,
      notes: notes ?? this.notes,
      externalUrl: externalUrl ?? this.externalUrl,
      bookingHint: bookingHint ?? this.bookingHint,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'source': source.name,
        if (refId != null) 'ref_id': refId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (estimatedDurationMin != null)
          'estimated_duration_min': estimatedDurationMin,
        if (travelFromPreviousMin != null)
          'travel_from_previous_min': travelFromPreviousMin,
        if (travelDistanceKm != null) 'travel_distance_km': travelDistanceKm,
        if (budgetMad != null) 'budget_mad': budgetMad,
        if (notes != null) 'notes': notes,
        if (externalUrl != null) 'external_url': externalUrl,
        if (bookingHint != null) 'booking_hint': bookingHint,
      };

  factory ItineraryStop.fromJson(Map<String, dynamic> json) {
    return ItineraryStop(
      id: json['id'] as String,
      type: ItineraryStopType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ItineraryStopType.custom,
      ),
      title: json['title'] as String? ?? 'Arrêt',
      source: ItineraryStopSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => ItineraryStopSource.user,
      ),
      refId: json['ref_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      estimatedDurationMin: json['estimated_duration_min'] as int?,
      travelFromPreviousMin: json['travel_from_previous_min'] as int?,
      travelDistanceKm: (json['travel_distance_km'] as num?)?.toDouble(),
      budgetMad: (json['budget_mad'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      externalUrl: json['external_url'] as String?,
      bookingHint: json['booking_hint'] as String?,
    );
  }
}
