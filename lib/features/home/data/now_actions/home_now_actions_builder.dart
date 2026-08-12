import 'package:flutter/material.dart';

import '../../../../core/location/location_constants.dart';
import '../../../explorer/data/place_catalog.dart';
import '../../../explorer/domain/place_repository.dart';
import '../../../prices/data/place_verified_price_links.dart';
import '../../../prices/data/price_observation_query.dart';
import '../../../prices/domain/models/price_observation.dart';
import '../../domain/models/weather_snapshot.dart';
import '../prayer/prayer_mapper.dart';

/// Type d'action Accueil — deep-link uniquement, pas de catalogue.
enum HomeNowActionKind { price, place, map }

/// Une action scannable « Utile maintenant ».
class HomeNowAction {
  const HomeNowAction({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.priceObservationId,
    this.placeId,
  });

  final String id;
  final HomeNowActionKind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? priceObservationId;
  final String? placeId;
}

/// Compose 0–3 actions utiles à partir de données Atlas déjà vérifiées.
///
/// Aucun prix inventé. Aucune recommandation Marrakech hors ville Marrakech.
class HomeNowActionsBuilder {
  const HomeNowActionsBuilder();

  static const _heatThresholdC = 34;

  /// Visites couvertes (musées / médersa) — priorité chaleur.
  static const _coveredVisitIds = <String>[
    'place-medersa-ben-youssef',
    'place-musee-dar-el-bacha',
    'place-maison-de-la-photographie',
    'place-ysl-museum',
    'place-macaal',
    'place-bahia',
  ];

  /// Visites en extérieur / jardin — soirée clémente.
  static const _outdoorVisitIds = <String>[
    'place-majorelle',
    'place-bahia',
    'place-el-badi',
    'place-koutoubia',
  ];

  List<HomeNowAction> build({
    required String cityName,
    required WeatherSnapshot weatherSnapshot,
    required List<PriceObservation> priceSource,
    PlaceRepository? placeRepository,
    DateTime? referenceTime,
  }) {
    final city = cityName.trim();
    if (city.isEmpty) return const [];

    final actions = <HomeNowAction>[];
    final prices = priceSource
        .where(
          (e) =>
              e.verificationStatus == PriceVerificationStatus.verified &&
              PriceObservationQuery.matchesCity(e, city),
        )
        .toList();

    final sim = _pickSimAction(prices);
    if (sim != null) actions.add(sim);

    if (_isMarrakech(city)) {
      final visit = _pickVisitAction(
        weatherSnapshot: weatherSnapshot,
        prices: prices,
        placeRepository: placeRepository,
        referenceTime: referenceTime,
      );
      if (visit != null) actions.add(visit);
    }

    if (_cityHasPlaces(city, placeRepository)) {
      actions.add(
        const HomeNowAction(
          id: 'map-near',
          kind: HomeNowActionKind.map,
          icon: Icons.map_outlined,
          title: 'Se repérer',
          subtitle: 'Ouvrir la carte près de moi',
        ),
      );
    }

    if (actions.isEmpty) return const [];
    return List.unmodifiable(actions.take(3));
  }

  bool _isMarrakech(String city) =>
      city.toLowerCase() == LocationConstants.fallbackCity.toLowerCase();

  bool _cityHasPlaces(String city, PlaceRepository? repository) {
    if (repository == null) return false;
    if (!repository.isCityCovered(city)) return false;
    return repository.getAll(cityName: city).isNotEmpty;
  }

  HomeNowAction? _pickSimAction(List<PriceObservation> prices) {
    final mobile = prices
        .where((e) => e.category == PriceIntelligenceCategory.mobilePlans)
        .toList();
    if (mobile.isEmpty) return null;
    PriceObservationQuery.sortInPlace(
      mobile,
      PriceIntelligenceSort.atlasRecommendation,
    );

    // Préférer Marhaba (arrivée) puis SIM prépayée.
    PriceObservation preferred = mobile.first;
    for (final item in mobile) {
      final name = item.itemName.toLowerCase();
      if (name.contains('marhaba')) {
        preferred = item;
        break;
      }
    }
    if (!preferred.itemName.toLowerCase().contains('marhaba')) {
      for (final item in mobile) {
        if (item.itemName.toLowerCase().contains('sim')) {
          preferred = item;
          break;
        }
      }
    }

    return HomeNowAction(
      id: 'sim-${preferred.id}',
      kind: HomeNowActionKind.price,
      icon: Icons.sim_card_outlined,
      title: 'Données mobiles',
      subtitle: '${preferred.itemName} — tarif vérifié',
      priceObservationId: preferred.id,
    );
  }

  HomeNowAction? _pickVisitAction({
    required WeatherSnapshot weatherSnapshot,
    required List<PriceObservation> prices,
    PlaceRepository? placeRepository,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? PrayerMapper.casablancaNow();
    final hot =
        weatherSnapshot.hasWeather &&
        weatherSnapshot.data != null &&
        weatherSnapshot.data!.temperature >= _heatThresholdC;
    final mildEvening =
        weatherSnapshot.hasWeather &&
        weatherSnapshot.data != null &&
        weatherSnapshot.data!.temperature >= 18 &&
        weatherSnapshot.data!.temperature <= 26 &&
        weatherSnapshot.data!.weatherCode <= 1 &&
        now.hour >= 16;

    final preferredIds = hot
        ? _coveredVisitIds
        : (mildEvening ? _outdoorVisitIds : _outdoorVisitIds);

    for (final placeId in preferredIds) {
      if (!PlaceCatalog.marrakechBetaCoreIds.contains(placeId)) continue;
      final place = placeRepository?.findById(placeId);
      if (place == null) continue;
      if (place.cityName.toLowerCase() != 'marrakech') continue;

      final hasTicket = PlaceVerifiedPriceLinks.hasLinks(placeId);
      final ticketSlug = hasTicket
          ? PlaceVerifiedPriceLinks.slugsForPlace(placeId).first
          : null;
      final ticket = ticketSlug == null
          ? null
          : PriceObservationQuery.findById(ticketSlug, source: prices);

      final subtitle = ticket != null
          ? '${place.name} — billet vérifié'
          : place.name;

      return HomeNowAction(
        id: 'visit-$placeId',
        kind: HomeNowActionKind.place,
        icon: Icons.account_balance_outlined,
        title: hot ? 'Visite à couvert' : 'Visite',
        subtitle: subtitle,
        placeId: placeId,
        priceObservationId: ticket?.id,
      );
    }
    return null;
  }
}
