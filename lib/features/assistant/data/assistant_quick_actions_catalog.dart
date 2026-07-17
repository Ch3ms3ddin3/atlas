import 'package:flutter/material.dart';

import '../../shell/presentation/shell_navigation_scope.dart';
import '../domain/models/assistant_quick_action.dart';

/// Actions rapides — navigation shell + itinéraires.
abstract final class AssistantQuickActionsCatalog {
  static const actions = <AssistantQuickAction>[
    AssistantQuickAction(
      id: 'explorer',
      label: 'Explorer',
      icon: Icons.explore_outlined,
      shellTabIndex: AtlasShellTab.explorer,
    ),
    AssistantQuickAction(
      id: 'map',
      label: 'Carte',
      icon: Icons.map_outlined,
      shellTabIndex: AtlasShellTab.map,
    ),
    AssistantQuickAction(
      id: 'itineraries',
      label: 'Voyages',
      icon: Icons.route_outlined,
      shellTabIndex: -1,
    ),
    AssistantQuickAction(
      id: 'prices',
      label: 'Prix',
      icon: Icons.payments_outlined,
      shellTabIndex: AtlasShellTab.prices,
    ),
  ];
}
