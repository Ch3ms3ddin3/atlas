import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/prayer_times_snapshot.dart';
import 'package:atlas/features/home/presentation/widgets/prayer_time_card.dart';

void main() {
  testWidgets('affiche le chargement sans horaires inventés', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: PrayerTimeCard(
            snapshot: PrayerTimesSnapshot.loading(),
          ),
        ),
      ),
    );

    expect(find.text('Chargement des horaires…'), findsOneWidget);
    expect(find.text('Asr'), findsNothing);
    expect(find.text('05:08'), findsNothing);
  });

  testWidgets('affiche l\'état indisponible sans faux horaires', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: PrayerTimeCard(
            snapshot: PrayerTimesSnapshot.unavailable(),
          ),
        ),
      ),
    );

    expect(find.text('Horaires indisponibles'), findsOneWidget);
    expect(find.text('Fajr'), findsNothing);
    expect(find.textContaining('données estimées'), findsNothing);
  });

  testWidgets('affiche le résumé live', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: PrayerTimeCard(
            snapshot: PrayerTimesSnapshot(
              state: PrayerLoadState.success,
              data: const PrayerTimeData(
                nextPrayerName: 'Maghrib',
                nextPrayerCountdown: 'dans 1h 10m',
                calculationMethod: 'AlAdhan · méthode Maroc',
                schedule: [
                  PrayerScheduleItem(
                    name: 'Fajr',
                    time: '05:08',
                    isCurrent: false,
                    isNext: false,
                  ),
                  PrayerScheduleItem(
                    name: 'Dhuhr',
                    time: '13:22',
                    isCurrent: false,
                    isNext: false,
                  ),
                  PrayerScheduleItem(
                    name: 'Asr',
                    time: '16:58',
                    isCurrent: true,
                    isNext: false,
                  ),
                  PrayerScheduleItem(
                    name: 'Maghrib',
                    time: '20:11',
                    isCurrent: false,
                    isNext: true,
                  ),
                  PrayerScheduleItem(
                    name: 'Isha',
                    time: '21:28',
                    isCurrent: false,
                    isNext: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Maghrib'), findsWidgets);
    expect(find.text('dans 1h 10m'), findsOneWidget);
    expect(find.text('AlAdhan · méthode Maroc'), findsOneWidget);
  });
}
