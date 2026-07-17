import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/datetime/casablanca_date_formatter.dart';
import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../data/event_device_calendar.dart';
import '../../data/resilient_event_repository.dart';
import '../../domain/event_repository.dart';
import '../../domain/models/atlas_event.dart';
import '../widgets/event_catalog_status_indicator.dart';
import '../widgets/event_reliability_chip.dart';

/// Détail d'un événement — source et statut toujours visibles.
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final repository = EventRepository();
    final event = repository.findById(eventId);
    final loadState = repository is ResilientEventRepository
        ? repository.loadState
        : EditorialCatalogLoadState.idle;

    return Scaffold(
      appBar: AppBar(title: const Text('Événement')),
      body: SafeArea(
        child: event == null
            ? const Center(child: Text('Événement introuvable'))
            : AtlasContentContainer(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AtlasSpacing.section),
                  children: [
                    const SizedBox(height: AtlasSpacing.lg),
                    EventCatalogStatusIndicator(loadState: loadState),
                    AtlasPageHeader(
                      title: event.title,
                      subtitle: event.categoryLabel,
                    ),
                    const SizedBox(height: AtlasSpacing.xl),
                    Wrap(
                      spacing: AtlasSpacing.sm,
                      runSpacing: AtlasSpacing.sm,
                      children: [
                        EventReliabilityChip(reliability: event.reliability),
                        _MetaChip(
                          label: event.isNational
                              ? 'National'
                              : event.cityName!,
                        ),
                        if (event.isAllDay) const _MetaChip(label: 'Journée entière'),
                      ],
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dates',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AtlasSpacing.sm),
                          Text(
                            _dateRangeLabel(event),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    Text(
                      'Source',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AtlasSpacing.sm),
                    Text(
                      event.source,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (event.lastVerifiedAt != null) ...[
                      const SizedBox(height: AtlasSpacing.xs),
                      Text(
                        'Vérifié le '
                        '${CasablancaDateFormatter.formatShortDate(event.lastVerifiedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AtlasTextStyles.metadata(
                                Theme.of(context).colorScheme,
                              ),
                            ),
                      ),
                    ],
                    if (event.reliability == EventReliability.provisional ||
                        event.reliability == EventReliability.estimated) ...[
                      const SizedBox(height: AtlasSpacing.md),
                      Text(
                        event.reliability == EventReliability.estimated
                            ? 'Date estimée — non confirmée officiellement.'
                            : 'Date provisoire — confirmation officielle possible.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AtlasTextStyles.helper(
                                Theme.of(context).colorScheme,
                              ),
                            ),
                      ),
                    ],
                    if (event.sourceUrl != null) ...[
                      const SizedBox(height: AtlasSpacing.lg),
                      TextButton.icon(
                        onPressed: () => _openUrl(event.sourceUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Voir la source'),
                      ),
                    ],
                    if (EventDeviceCalendar.isSupported) ...[
                      const SizedBox(height: AtlasSpacing.xl),
                      FilledButton.icon(
                        onPressed: () => _addToCalendar(context, event),
                        icon: const Icon(Icons.event_available_outlined),
                        label: const Text('Ajouter au calendrier'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String _dateRangeLabel(AtlasEvent event) {
    final start = CasablancaDateFormatter.formatLongDate(event.startAt);
    final end = CasablancaDateFormatter.formatLongDate(event.effectiveEnd);
    if (start == end) return start;
    return '$start → $end';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _addToCalendar(BuildContext context, AtlasEvent event) async {
    final ok = await EventDeviceCalendar.add(event);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Ouverture du calendrier…'
              : 'Impossible d\'ajouter l\'événement.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.md,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
