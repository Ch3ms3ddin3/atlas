import 'itinerary_day.dart';
import 'itinerary_enums.dart';

/// Estimation budgétaire — fourchettes, jamais de prix inventés précis.
class TripBudgetEstimate {
  const TripBudgetEstimate({
    this.foodMadMin,
    this.foodMadMax,
    this.transportMadMin,
    this.transportMadMax,
    this.activitiesMadMin,
    this.activitiesMadMax,
    this.lodgingMadMin,
    this.lodgingMadMax,
    this.notes,
  });

  final double? foodMadMin;
  final double? foodMadMax;
  final double? transportMadMin;
  final double? transportMadMax;
  final double? activitiesMadMin;
  final double? activitiesMadMax;
  final double? lodgingMadMin;
  final double? lodgingMadMax;
  final String? notes;

  double? get totalMin {
    final parts = [
      foodMadMin,
      transportMadMin,
      activitiesMadMin,
      lodgingMadMin,
    ].whereType<double>();
    if (parts.isEmpty) return null;
    return parts.fold<double>(0, (a, b) => a + b);
  }

  double? get totalMax {
    final parts = [
      foodMadMax,
      transportMadMax,
      activitiesMadMax,
      lodgingMadMax,
    ].whereType<double>();
    if (parts.isEmpty) return null;
    return parts.fold<double>(0, (a, b) => a + b);
  }

  Map<String, dynamic> toJson() => {
        if (foodMadMin != null) 'food_mad_min': foodMadMin,
        if (foodMadMax != null) 'food_mad_max': foodMadMax,
        if (transportMadMin != null) 'transport_mad_min': transportMadMin,
        if (transportMadMax != null) 'transport_mad_max': transportMadMax,
        if (activitiesMadMin != null) 'activities_mad_min': activitiesMadMin,
        if (activitiesMadMax != null) 'activities_mad_max': activitiesMadMax,
        if (lodgingMadMin != null) 'lodging_mad_min': lodgingMadMin,
        if (lodgingMadMax != null) 'lodging_mad_max': lodgingMadMax,
        if (notes != null) 'notes': notes,
      };

  factory TripBudgetEstimate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TripBudgetEstimate();
    return TripBudgetEstimate(
      foodMadMin: (json['food_mad_min'] as num?)?.toDouble(),
      foodMadMax: (json['food_mad_max'] as num?)?.toDouble(),
      transportMadMin: (json['transport_mad_min'] as num?)?.toDouble(),
      transportMadMax: (json['transport_mad_max'] as num?)?.toDouble(),
      activitiesMadMin: (json['activities_mad_min'] as num?)?.toDouble(),
      activitiesMadMax: (json['activities_mad_max'] as num?)?.toDouble(),
      lodgingMadMin: (json['lodging_mad_min'] as num?)?.toDouble(),
      lodgingMadMax: (json['lodging_mad_max'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// Voyage multi-jours Atlas.
class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.primaryCity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.cities = const [],
    this.days = const [],
    this.budget,
    this.pace = 'balanced',
    this.isActive = true,
    this.syncPending = false,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String primaryCity;
  final List<String> cities;
  final List<ItineraryDay> days;
  final TripStatus status;
  final TripBudgetEstimate? budget;
  final String pace;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool syncPending;

  int get dayCount {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  bool get isWithinLimit => dayCount >= 1 && dayCount <= ItineraryLimits.maxDays;

  Trip copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? primaryCity,
    List<String>? cities,
    List<ItineraryDay>? days,
    TripStatus? status,
    TripBudgetEstimate? budget,
    String? pace,
    DateTime? updatedAt,
    bool? isActive,
    bool? syncPending,
  }) {
    return Trip(
      id: id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      primaryCity: primaryCity ?? this.primaryCity,
      cities: cities ?? this.cities,
      days: days ?? this.days,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      pace: pace ?? this.pace,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncPending: syncPending ?? this.syncPending,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start_date': _dateOnly(startDate),
        'end_date': _dateOnly(endDate),
        'primary_city': primaryCity,
        'cities': cities,
        'days': days.map((d) => d.toJson()).toList(),
        'status': status.name,
        if (budget != null) 'budget': budget!.toJson(),
        'pace': pace,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'is_active': isActive,
        'sync_pending': syncPending,
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? const [];
    final rawCities = json['cities'] as List<dynamic>? ?? const [];
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Voyage',
      startDate: _parseDate(json['start_date'] as String?),
      endDate: _parseDate(json['end_date'] as String?),
      primaryCity: json['primary_city'] as String? ?? 'Marrakech',
      cities: [for (final c in rawCities) c.toString()],
      days: [
        for (final item in rawDays)
          if (item is Map<String, dynamic>) ItineraryDay.fromJson(item),
      ],
      status: TripStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TripStatus.draft,
      ),
      budget: TripBudgetEstimate.fromJson(
        json['budget'] as Map<String, dynamic>?,
      ),
      pace: json['pace'] as String? ?? 'balanced',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      isActive: json['is_active'] as bool? ?? true,
      syncPending: json['sync_pending'] as bool? ?? false,
    );
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  static DateTime _parseDate(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '') ?? DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
