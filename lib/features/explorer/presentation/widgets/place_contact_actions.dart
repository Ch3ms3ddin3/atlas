import 'package:flutter/material.dart';

import '../../../../core/platform/atlas_external_links.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../domain/models/place_models.dart';
import '../../domain/place_browse_filters.dart';
import 'place_detail_section.dart';

/// Actions de contact — affichées uniquement si la donnée existe.
class PlaceContactActions extends StatelessWidget {
  const PlaceContactActions({
    super.key,
    required this.place,
    this.onLaunchFailed,
  });

  final PlaceGuide place;
  final VoidCallback? onLaunchFailed;

  @override
  Widget build(BuildContext context) {
    final hasAtlasMap = place.hasCoordinates;
    if (!place.hasContactActions && !hasAtlasMap) {
      return const SizedBox.shrink();
    }

    final actions = <_ContactAction>[
      if (hasAtlasMap)
        _ContactAction(
          icon: Icons.map_outlined,
          label: 'Carte Atlas',
          onPressed: () => _openOnAtlasMap(context),
        ),
      if (place.hasCoordinates)
        _ContactAction(
          icon: Icons.near_me_outlined,
          label: 'Itinéraire',
          onPressed: () => _open(
            AtlasExternalLinks.mapsUri(
              latitude: place.latitude!,
              longitude: place.longitude!,
            ),
          ),
        ),
      if (place.hasPhone)
        _ContactAction(
          icon: Icons.phone_outlined,
          label: 'Appeler',
          onPressed: () => _open(AtlasExternalLinks.phoneUri(place.phone!)),
        ),
      if (place.hasWebsite)
        _ContactAction(
          icon: Icons.language_outlined,
          label: 'Site web',
          onPressed: () => _open(AtlasExternalLinks.websiteUri(place.website!)),
        ),
      if (place.hasEmail)
        _ContactAction(
          icon: Icons.mail_outline,
          label: 'E-mail',
          onPressed: () => _open(AtlasExternalLinks.emailUri(place.email!)),
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlaceDetailSectionHeader(title: 'Contact'),
        Wrap(
          spacing: AtlasSpacing.sm,
          runSpacing: AtlasSpacing.sm,
          children: [
            for (final action in actions)
              OutlinedButton.icon(
                onPressed: action.onPressed,
                icon: Icon(action.icon, size: 18),
                label: Text(action.label),
              ),
          ],
        ),
      ],
    );
  }

  void _openOnAtlasMap(BuildContext context) {
    PlaceBrowseFilters.instance.requestFocusPlace(
      placeId: place.id,
      cityName: place.cityName,
    );
    final navigateToTab = ShellNavigationScope.maybeOf(context)?.navigateToTab;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateToTab?.call(AtlasShellTab.map);
    });
  }

  Future<void> _open(Uri? uri) async {
    if (uri == null) {
      onLaunchFailed?.call();
      return;
    }
    final opened = await AtlasExternalLinks.open(uri);
    if (!opened) onLaunchFailed?.call();
  }
}

class _ContactAction {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}
