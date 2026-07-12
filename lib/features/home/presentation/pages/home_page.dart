import 'package:flutter/material.dart';

import '../../data/mock/home_mock_data.dart';
import '../widgets/admission_temporaire_card.dart';
import '../widgets/daily_briefing_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/home_section_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recommended_places_card.dart';
import '../widgets/today_essentials_section.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_reveal.dart';
import '../../domain/models/home_models.dart';

/// Répond à : « Qu'est-ce que j'ai besoin de savoir maintenant ? »
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onQuickActionTap(QuickActionData action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${action.label} — bientôt disponible'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    child: GreetingHeader(data: HomeMockData.greeting),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 60),
                    child: const HomeSectionHeader(title: 'Briefing du jour'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 100),
                    child: DailyBriefingSection(
                      weather: HomeMockData.weather,
                      prayerTime: HomeMockData.prayerTime,
                      exchangeRate: HomeMockData.exchangeRate,
                      holidayStatus: HomeMockData.holidayStatus,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 140),
                    child: const HomeSectionHeader(title: 'À savoir aujourd\'hui'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 180),
                    child: TodayEssentialsSection(data: HomeMockData.todayEssentials),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 220),
                    child: const HomeSectionHeader(title: 'Actions rapides'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 260),
                    child: QuickActionsGrid(
                      actions: HomeMockData.quickActions,
                      onActionTap: _onQuickActionTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 300),
                    child: const HomeSectionHeader(title: 'Administratif'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 340),
                    child: AdmissionTemporaireCard(
                      data: HomeMockData.admissionTemporaire,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 380),
                    child: const HomeSectionHeader(title: 'Recommandations'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 420),
                    child: RecommendedPlacesSection(
                      places: HomeMockData.recommendedPlaces,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  Center(
                    child: Text(
                      HomeMockData.lastUpdated,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
