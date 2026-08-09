import 'package:flutter/material.dart';

import '../../domain/models/weather_snapshot.dart';

/// Legacy builder — no longer mounted on Home V5 (P3 authenticity).
///
/// Returns an empty list so callers never invent filler tips.
/// Prefer [DailyInsightBuilder] for the single conditional Home tip.
class PourVousBuilder {
  const PourVousBuilder();

  List<PourVousRecommendation> build({
    required WeatherSnapshot weatherSnapshot,
    required String cityName,
  }) {
    return const [];
  }
}

/// Recommandation contextuelle (legacy shape for [PourVousSection]).
class PourVousRecommendation {
  const PourVousRecommendation({required this.message, required this.icon});

  final String message;
  final IconData icon;

  String get title {
    final parts = message.split(' — ');
    return parts.first.trim();
  }

  String? get detail {
    final parts = message.split(' — ');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(' — ').trim();
  }
}
