import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/atlas_event.dart';
import '../pages/events_calendar_page.dart';
import 'event_list_tile_card.dart';

/// Sections Home « Aujourd'hui au Maroc » et « À venir ».
class HomeEventsSections extends StatelessWidget {
  const HomeEventsSections({
    super.key,
    required this.todayEvents,
    required this.upcomingEvents,
    this.cityName,
  });

  final List<AtlasEvent> todayEvents;
  final List<AtlasEvent> upcomingEvents;
  final String? cityName;

  @override
  Widget build(BuildContext context) {
    final hasToday = todayEvents.isNotEmpty;
    final hasUpcoming = upcomingEvents.isNotEmpty;
    if (!hasToday && !hasUpcoming) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasToday) ...[
          const SizedBox(height: AtlasSpacing.section),
          _SectionHeader(
            title: 'Aujourd\'hui au Maroc',
            actionLabel: 'Agenda',
            onActionTap: () => openEventsCalendar(
              context,
              initialCity: cityName,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          for (final event in todayEvents.take(3)) ...[
            EventListTileCard(
              event: event,
              compact: true,
              onTap: () => openEventDetail(context, event.id),
            ),
            const SizedBox(height: AtlasSpacing.md),
          ],
        ],
        if (hasUpcoming) ...[
          SizedBox(height: hasToday ? AtlasSpacing.lg : AtlasSpacing.section),
          _SectionHeader(
            title: 'À venir',
            actionLabel: 'Tout voir',
            onActionTap: () => openEventsCalendar(
              context,
              initialCity: cityName,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          for (final event in upcomingEvents) ...[
            EventListTileCard(
              event: event,
              compact: true,
              onTap: () => openEventDetail(context, event.id),
            ),
            const SizedBox(height: AtlasSpacing.md),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
