import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';
import 'prayer_time_card.dart';
import 'weather_card.dart';

/// Briefing visuel — météo et prière côte à côte (ou empilées sur mobile).
class DailyBriefingSection extends StatelessWidget {
  const DailyBriefingSection({
    super.key,
    required this.weatherSnapshot,
    required this.prayerSnapshot,
    this.onPrayerTap,
  });

  final WeatherSnapshot weatherSnapshot;
  final PrayerTimesSnapshot prayerSnapshot;
  final VoidCallback? onPrayerTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: WeatherCard(
                  snapshot: weatherSnapshot,
                  animateEntrance: true,
                ),
              ),
              const SizedBox(width: AtlasSpacing.lg),
              Expanded(
                flex: 2,
                child: PrayerTimeCard(
                  snapshot: prayerSnapshot,
                  onTap: onPrayerTap,
                  animateEntrance: true,
                  entranceDelay: AtlasMotion.staggerDelay,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            WeatherCard(
              snapshot: weatherSnapshot,
              animateEntrance: true,
            ),
            const SizedBox(height: AtlasSpacing.lg),
            PrayerTimeCard(
              snapshot: prayerSnapshot,
              onTap: onPrayerTap,
              animateEntrance: true,
              entranceDelay: AtlasMotion.staggerDelay,
            ),
          ],
        );
      },
    );
  }
}
