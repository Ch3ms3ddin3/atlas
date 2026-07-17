import '../domain/models/trip.dart';

/// Estimation budgétaire à partir de bandes Price Intelligence / heuristiques.
///
/// Ne fabrique jamais de prix « exacts » — fourchettes indicatives MAD.
abstract final class ItineraryBudgetEstimator {
  static TripBudgetEstimate estimate({
    required int dayCount,
    required String budgetBand,
    required int stopCount,
    bool includeLodgingStub = true,
  }) {
    final days = dayCount.clamp(1, 14);
    final (foodMin, foodMax, transportMin, transportMax, actMin, actMax,
        lodgeMin, lodgeMax) = switch (budgetBand) {
      'budget' => (80.0, 150.0, 30.0, 80.0, 0.0, 100.0, 200.0, 400.0),
      'premium' => (200.0, 400.0, 80.0, 200.0, 150.0, 400.0, 800.0, 1600.0),
      _ => (120.0, 250.0, 40.0, 120.0, 50.0, 200.0, 350.0, 700.0),
    };

    final activityFactor = 1 + (stopCount / (days * 4)).clamp(0.0, 1.0) * 0.3;

    return TripBudgetEstimate(
      foodMadMin: foodMin * days,
      foodMadMax: foodMax * days,
      transportMadMin: transportMin * days,
      transportMadMax: transportMax * days,
      activitiesMadMin: actMin * days * activityFactor,
      activitiesMadMax: actMax * days * activityFactor,
      lodgingMadMin: includeLodgingStub ? lodgeMin * days : null,
      lodgingMadMax: includeLodgingStub ? lodgeMax * days : null,
      notes:
          'Fourchettes indicatives MAD (repères Atlas). Vérifiez les prix locaux — '
          'aucune réservation intégrée.',
    );
  }
}
