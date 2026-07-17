import 'package:flutter/material.dart';

import '../domain/itinerary_repository.dart';

class ItineraryScope extends InheritedNotifier<ItineraryRepository> {
  const ItineraryScope({
    super.key,
    required ItineraryRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static ItineraryRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ItineraryScope>();
    assert(scope != null, 'ItineraryScope introuvable.');
    return scope!.notifier!;
  }

  static ItineraryRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ItineraryScope>()
        ?.notifier;
  }

  static ItineraryRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ItineraryScope>();
    assert(scope != null, 'ItineraryScope introuvable.');
    return scope!.notifier!;
  }
}
