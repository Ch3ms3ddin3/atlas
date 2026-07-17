import 'itinerary_stop.dart';

/// Une journée d'itinéraire.
class ItineraryDay {
  const ItineraryDay({
    required this.id,
    required this.dayIndex,
    required this.date,
    required this.cityName,
    this.notes,
    this.stops = const [],
    this.weatherSummary,
    this.prayerSummary,
  });

  final String id;
  final int dayIndex;
  final DateTime date;
  final String cityName;
  final String? notes;
  final List<ItineraryStop> stops;
  final String? weatherSummary;
  final String? prayerSummary;

  ItineraryDay copyWith({
    int? dayIndex,
    DateTime? date,
    String? cityName,
    String? notes,
    List<ItineraryStop>? stops,
    String? weatherSummary,
    String? prayerSummary,
  }) {
    return ItineraryDay(
      id: id,
      dayIndex: dayIndex ?? this.dayIndex,
      date: date ?? this.date,
      cityName: cityName ?? this.cityName,
      notes: notes ?? this.notes,
      stops: stops ?? this.stops,
      weatherSummary: weatherSummary ?? this.weatherSummary,
      prayerSummary: prayerSummary ?? this.prayerSummary,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_index': dayIndex,
        'date': DateTime(date.year, date.month, date.day)
            .toIso8601String()
            .split('T')
            .first,
        'city_name': cityName,
        if (notes != null) 'notes': notes,
        'stops': stops.map((s) => s.toJson()).toList(),
        if (weatherSummary != null) 'weather_summary': weatherSummary,
        if (prayerSummary != null) 'prayer_summary': prayerSummary,
      };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String? ?? '';
    final parsed = DateTime.tryParse(rawDate) ?? DateTime.now();
    final rawStops = json['stops'] as List<dynamic>? ?? const [];
    return ItineraryDay(
      id: json['id'] as String,
      dayIndex: json['day_index'] as int? ?? 0,
      date: DateTime(parsed.year, parsed.month, parsed.day),
      cityName: json['city_name'] as String? ?? 'Marrakech',
      notes: json['notes'] as String?,
      stops: [
        for (final item in rawStops)
          if (item is Map<String, dynamic>) ItineraryStop.fromJson(item),
      ],
      weatherSummary: json['weather_summary'] as String?,
      prayerSummary: json['prayer_summary'] as String?,
    );
  }
}
