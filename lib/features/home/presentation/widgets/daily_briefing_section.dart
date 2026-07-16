import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import 'exchange_rate_card.dart';
import 'holiday_status_card.dart';
import 'prayer_time_card.dart';
import 'weather_card.dart';

/// Briefing quotidien — météo en tête, prière secondaire, change et férié discrets.
class DailyBriefingSection extends StatelessWidget {
  const DailyBriefingSection({
    super.key,
    required this.weather,
    this.isWeatherLoading = false,
    required this.prayerSnapshot,
    required this.exchangeRateSnapshot,
    required this.holidayStatus,
    this.onPrayerTap,
  });

  final WeatherData weather;
  final bool isWeatherLoading;
  final PrayerTimesSnapshot prayerSnapshot;
  final ExchangeRateSnapshot exchangeRateSnapshot;
  final HolidayStatusData holidayStatus;
  final VoidCallback? onPrayerTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: WeatherCard(
                      data: weather,
                      isLoading: isWeatherLoading,
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
              ),
              const SizedBox(height: AtlasSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ExchangeRateCard(
                      snapshot: exchangeRateSnapshot,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: AtlasSpacing.lg),
                  Expanded(
                    child: HolidayStatusCard(data: holidayStatus, compact: true),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            WeatherCard(
              data: weather,
              isLoading: isWeatherLoading,
              animateEntrance: true,
            ),
            const SizedBox(height: AtlasSpacing.lg),
            PrayerTimeCard(
              snapshot: prayerSnapshot,
              onTap: onPrayerTap,
              animateEntrance: true,
              entranceDelay: AtlasMotion.staggerDelay,
            ),
            const SizedBox(height: AtlasSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ExchangeRateCard(
                    snapshot: exchangeRateSnapshot,
                    compact: true,
                  ),
                ),
                const SizedBox(width: AtlasSpacing.md),
                Expanded(
                  child: HolidayStatusCard(data: holidayStatus, compact: true),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
