import 'package:flutter/material.dart';

import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../domain/itinerary_repository.dart';
import '../../domain/models/trip.dart';
import '../itinerary_scope.dart';
import '../widgets/trip_create_sheet.dart';
import 'trip_detail_page.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      AtlasPageRoute(page: const TripListPage()),
    );
  }

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  ItineraryRepository? _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = ItineraryScope.of(context);
    if (!identical(repo, _repo)) {
      _repo?.removeListener(_onChange);
      _repo = repo;
      _repo!.addListener(_onChange);
      if (!_repo!.isLoaded) {
        _repo!.load();
      }
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final id = await TripCreateSheet.show(context);
    if (!mounted || id == null) return;
    await Navigator.of(context).push(
      AtlasPageRoute(page: TripDetailPage(tripId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ItineraryScope.of(context);
    final trips = repo.activeTrips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinéraires'),
        actions: [
          IconButton(
            tooltip: 'Nouveau voyage',
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Planifier'),
      ),
      body: SafeArea(
        child: trips.isEmpty
            ? AtlasContentContainer(
                child: Column(
                  children: [
                    const AtlasPageHeader(
                      title: 'Vos voyages au Maroc',
                      subtitle:
                          'Multi-jours, météo, prières, favoris et budget Atlas.',
                    ),
                    const AtlasEmptyState(
                      icon: Icons.map_outlined,
                      message:
                          'Aucun itinéraire enregistré. '
                          'Générez un voyage avec Atlas ou créez-le à la main — '
                          'disponible hors ligne une fois sauvegardé.',
                    ),
                    FilledButton(
                      onPressed: _create,
                      child: const Text('Créer un itinéraire'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AtlasSpacing.pageHorizontal,
                  AtlasSpacing.lg,
                  AtlasSpacing.pageHorizontal,
                  100,
                ),
                itemCount: trips.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AtlasSpacing.md),
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return _TripTile(
                    trip: trip,
                    onOpen: () {
                      Navigator.of(context).push(
                        AtlasPageRoute(
                          page: TripDetailPage(tripId: trip.id),
                        ),
                      );
                    },
                    onDelete: () => repo.deleteTrip(trip.id),
                  );
                },
              ),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({
    required this.trip,
    required this.onOpen,
    required this.onDelete,
  });

  final Trip trip;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AtlasColors.terracottaGhost,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: AtlasColors.terracotta,
            ),
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  '${trip.primaryCity} · ${trip.dayCount} jour'
                  '${trip.dayCount > 1 ? 's' : ''} · '
                  '${trip.days.fold<int>(0, (s, d) => s + d.stops.length)} arrêts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AtlasColors.midnightBlueMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
