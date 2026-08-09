import 'package:flutter/widgets.dart';

import '../domain/itinerary_repository.dart';
import 'itinerary_scope.dart';

/// Réinjecte [ItineraryScope] sur une route poussée hors de l'arbre du shell.
Widget wrapWithItineraryScope(ItineraryRepository repository, Widget child) {
  return ItineraryScope(repository: repository, child: child);
}
