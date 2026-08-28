import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/datetime/atlas_display_clock.dart';
import 'package:atlas/core/location/atlas_city_source.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/beta/presentation/widgets/atlas_beta_banner.dart';
import 'package:atlas/features/home/data/greeting/greeting_repository.dart';
import 'package:atlas/features/home/data/morning_brief/morning_brief_builder.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/presentation/widgets/greeting_header.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  test('France auto : heure locale France, pas Marrakech / Casablanca', () {
    final franceLocal = DateTime(2026, 8, 28, 8, 29);
    final clock = AtlasDisplayClock.nowFor(
      citySource: AtlasCitySource.auto,
      deviceNow: franceLocal,
    );
    expect(AtlasDisplayClock.formatHm(clock), '08:29');
    expect(clock.hour, 8);
    expect(clock, isNot(AtlasDisplayClock.casablancaNow(franceLocal.toUtc())));
  });

  test(
    'auto hors Maroc : bannière et briefing ne prétendent pas Marrakech',
    () {
      expect(AtlasBetaBanner.titleFor(), 'Atlas Private Beta');
      expect(AtlasBetaBanner.titleFor(locationLabel: ''), 'Atlas Private Beta');
      expect(
        AtlasBetaBanner.titleFor(locationLabel: 'Paris'),
        'Atlas Private Beta · Paris',
      );

      const profile = UserProfile(
        firstName: UserProfile.defaultFirstName,
        preferredCity: UserProfile.defaultPreferredCity,
        language: AtlasLanguage.french,
        userType: AtlasUserType.resident,
      );
      expect(profile.citySource, AtlasCitySource.auto);
      expect(profile.preferredCity, 'Marrakech');
      final bannerLabel = profile.citySource == AtlasCitySource.manual
          ? profile.preferredCity
          : null;
      expect(
        AtlasBetaBanner.titleFor(locationLabel: bannerLabel),
        isNot(contains('Marrakech')),
      );
      expect(MorningBriefData.titleFor(''), 'Aujourd\'hui');
    },
  );

  test('manual Marrakech : contexte ville conservé', () {
    expect(
      AtlasBetaBanner.titleFor(locationLabel: 'Marrakech'),
      'Atlas Private Beta · Marrakech',
    );
    const repo = GreetingRepository();
    final data = repo.build(
      firstName: 'Voyageur',
      city: 'Marrakech',
      citySource: AtlasCitySource.manual,
      referenceTime: DateTime(2026, 8, 28, 7, 29),
    );
    expect(data.city, 'Marrakech');
    expect(MorningBriefData.titleFor('Marrakech'), 'Aujourd\'hui à Marrakech');
  });

  test('GreetingRepository auto : n\'invente pas une ville Marrakech', () {
    const repo = GreetingRepository();
    final data = repo.build(
      firstName: 'Voyageur',
      city: '',
      citySource: AtlasCitySource.auto,
      referenceTime: DateTime(2026, 8, 28, 8, 29),
    );
    expect(data.city, isEmpty);
    expect(data.dateLabel.toLowerCase(), contains('août'));
  });

  testWidgets('Accueil auto France : 08:29, pas Marrakech', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: GreetingHeader(
            data: const GreetingData(
              userName: 'Voyageur',
              city: '',
              dateLabel: 'vendredi 28 août 2026',
            ),
            citySource: AtlasCitySource.auto,
            clockNow: () => DateTime(2026, 8, 28, 8, 29),
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('08:29'), findsOneWidget);
    expect(find.textContaining('07:29'), findsNothing);
    expect(find.textContaining('Marrakech'), findsNothing);
  });

  testWidgets('Accueil manual Marrakech : ville et fuseau Casablanca', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: GreetingHeader(
            data: const GreetingData(
              userName: 'Voyageur',
              city: 'Marrakech',
              dateLabel: 'vendredi 28 août 2026',
            ),
            citySource: AtlasCitySource.manual,
            clockNow: () => AtlasDisplayClock.nowFor(
              citySource: AtlasCitySource.manual,
              utcNow: DateTime.utc(2026, 8, 28, 6, 29),
            ),
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Marrakech'), findsOneWidget);
    expect(find.textContaining('07:29'), findsOneWidget);
  });
}
