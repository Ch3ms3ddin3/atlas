import 'package:flutter/widgets.dart';

import '../../profile/domain/profile_repository.dart';
import '../../profile/presentation/profile_scope.dart';
import '../../shell/presentation/shell_navigation_scope.dart';
import '../../itineraries/domain/itinerary_repository.dart';
import '../../itineraries/presentation/itinerary_scope.dart';
import '../domain/assistant_repository.dart';
import 'assistant_scope.dart';

/// Réinjecte les scopes requis sur une route Assistant poussée hors du shell.
Widget wrapWithAssistantRouteScopes({
  required AssistantRepository assistantRepository,
  required ProfileRepository profileRepository,
  required ItineraryRepository itineraryRepository,
  required void Function(int index) navigateToTab,
  required Widget child,
}) {
  return ProfileScope(
    repository: profileRepository,
    child: AssistantScope(
      repository: assistantRepository,
      child: ItineraryScope(
        repository: itineraryRepository,
        child: ShellNavigationScope(navigateToTab: navigateToTab, child: child),
      ),
    ),
  );
}
