import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/core/platform/atlas_external_links.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/content_reports/data/local_content_reports_repository.dart';
import 'package:atlas/features/content_reports/domain/content_report_entity_type.dart';
import 'package:atlas/features/content_reports/domain/content_report_type.dart';
import 'package:atlas/features/content_reports/presentation/content_reports_scope.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_record_mapper.dart';
import 'package:atlas/features/explorer/data/resilient_place_repository.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_catalog_status_indicator.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceRepository.resetForTest();
    AtlasExternalLinks.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    AtlasExternalLinks.resetForTest();
  });

  PlaceGuide basePlace({
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
    String? email,
    List<String> imageUrls = const [],
    List<String> amenities = const [],
    List<String> accessibilityFeatures = const [],
    PlaceOpeningHours? openingHours,
    List<String>? practicalTips,
  }) {
    return PlaceGuide(
      id: 'place-test',
      name: 'Lieu Test',
      cityName: 'Marrakech',
      category: PlaceCategory.jardin,
      categoryLabel: 'Jardin',
      neighborhood: 'Gueliz',
      priceLevel: '€€',
      isEditorsPick: true,
      imageColor: const Color(0xFF2D6A4F),
      summary: 'Une description éditoriale longue pour la fiche premium.',
      practicalTips: practicalTips ??
          const [
            'Conseil un',
            'Conseil deux',
          ],
      bestTimeToVisit: 'Le matin',
      address: address,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
      website: website,
      email: email,
      imageUrls: imageUrls,
      amenities: amenities,
      accessibilityFeatures: accessibilityFeatures,
      openingHours: openingHours,
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required PlaceGuide? place,
    String? placeId,
    PlaceRepository? repository,
    LocalContentReportsRepository? reports,
  }) async {
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    final contentReports = reports ?? LocalContentReportsRepository();
    await contentReports.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: ContentReportsScope(
          repository: contentReports,
          child: FavoritesScope(
            repository: favorites,
            child: PlaceDetailPage(
              place: place,
              placeId: placeId ?? place?.id,
              repository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche hero, description et conseils du catalogue', (
    tester,
  ) async {
    final place = LocalPlaceRepository().findById('place-majorelle')!;
    await pumpDetail(tester, place: place);

    expect(find.text('Jardin Majorelle'), findsWidgets);
    expect(find.text('Jardin'), findsOneWidget);
    expect(find.text('Marrakech'), findsOneWidget);
    expect(find.textContaining('Jardin botanique'), findsOneWidget);
    expect(find.text('Conseils pratiques'), findsOneWidget);
    expect(find.byTooltip('Ajouter aux favoris'), findsOneWidget);
    expect(find.byTooltip('Signaler un problème'), findsOneWidget);
  });

  testWidgets('masque sections sans données (pas de faux contenus)', (
    tester,
  ) async {
    await pumpDetail(tester, place: basePlace(practicalTips: const []));

    expect(find.text('Adresse'), findsNothing);
    expect(find.text('Contact'), findsNothing);
    expect(find.text('Itinéraire'), findsNothing);
    expect(find.text('Appeler'), findsNothing);
    expect(find.text('Site web'), findsNothing);
    expect(find.text('E-mail'), findsNothing);
    expect(find.text('Horaires'), findsNothing);
    expect(find.text('Galerie'), findsNothing);
    expect(find.text('Accessibilité'), findsNothing);
    expect(find.text('Équipements'), findsNothing);
    expect(find.text('Conseils pratiques'), findsNothing);
    expect(find.text('Meilleur moment'), findsOneWidget);
  });

  testWidgets('affiche sections uniquement quand les données existent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final opened = <Uri>[];
    AtlasExternalLinks.openForTest((uri) async {
      opened.add(uri);
      return true;
    });

    await pumpDetail(
      tester,
      place: basePlace(
        address: 'Rue Yves Saint Laurent, Marrakech',
        latitude: 31.6416,
        longitude: -8.0031,
        phone: '+212524313047',
        website: 'https://www.jardinmajorelle.com',
        email: 'info@example.com',
        imageUrls: const ['https://cdn.example/photo.jpg'],
        amenities: const ['Wifi'],
        accessibilityFeatures: const ['Accès fauteuil'],
        openingHours: const PlaceOpeningHours(
          entries: [
            PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '08:00–18:00'),
          ],
        ),
      ),
    );

    expect(find.text('Adresse'), findsWidgets);
    expect(find.text('Rue Yves Saint Laurent, Marrakech'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Itinéraire'), findsOneWidget);
    expect(find.text('Appeler'), findsOneWidget);
    expect(find.text('Site web'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Horaires'), findsOneWidget);
    expect(find.text('Lundi'), findsOneWidget);
    expect(find.text('Galerie'), findsOneWidget);
    expect(find.text('Accessibilité'), findsOneWidget);
    expect(find.text('Équipements'), findsOneWidget);

    await tester.ensureVisible(find.text('Itinéraire'));
    await tester.tap(find.text('Itinéraire'));
    await tester.pumpAndSettle();
    expect(opened, isNotEmpty);
    expect(opened.first.toString(), contains('31.6416'));
  });

  testWidgets('soumet un signalement depuis le hero', (tester) async {
    final reports = LocalContentReportsRepository();
    await reports.load();
    final place = LocalPlaceRepository().findById('place-majorelle')!;

    await pumpDetail(tester, place: place, reports: reports);

    await tester.tap(find.byTooltip('Signaler un problème'));
    await tester.pumpAndSettle();

    expect(find.text('Signaler un problème'), findsWidgets);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(reports.reports, hasLength(1));
    expect(reports.reports.single.entityType, ContentReportEntityType.place);
    expect(reports.reports.single.entitySlug, 'place-majorelle');
    expect(reports.reports.single.reportType, ContentReportType.incorrect);
  });

  testWidgets('empty state pour un slug inconnu', (tester) async {
    final repository = LocalPlaceRepository();
    await pumpDetail(
      tester,
      place: null,
      placeId: 'place-inconnu',
      repository: repository,
    );

    expect(find.textContaining('Lieu introuvable'), findsOneWidget);
  });

  testWidgets('indicateur stale visible sur la fiche', (tester) async {
    final repository = ResilientPlaceRepository(
      local: LocalPlaceRepository(),
      fetchRemote: () async => const [],
    );
    await repository.warmUp();
    expect(repository.loadState, EditorialCatalogLoadState.stale);

    final place = repository.findById('place-majorelle')!;
    await pumpDetail(tester, place: place, repository: repository);

    expect(find.byType(PlaceCatalogStatusIndicator), findsOneWidget);
    expect(find.text('Catalogue local'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsWidgets);
  });

  group('PlaceRecordMapper champs premium', () {
    test('mappe les nouveaux champs optionnels', () {
      final guide = PlaceRecordMapper.fromRow({
        'slug': 'place-full',
        'name': 'Complet',
        'city_name': 'Rabat',
        'category': 'monument',
        'category_label': 'Monument',
        'neighborhood': 'Centre',
        'price_level': '€',
        'summary': 'Résumé',
        'practical_tips': <String>[],
        'address': 'Avenue Mohammed V',
        'latitude': 34.02,
        'longitude': -6.83,
        'phone': '+212537000000',
        'website': 'https://example.com',
        'email': 'hello@example.com',
        'image_urls': ['https://cdn.example/a.jpg'],
        'amenities': ['Parking'],
        'accessibility_features': ['Ascenseur'],
        'opening_hours': {
          'note': 'Fermé les jours fériés',
          'entries': [
            {'day': 'Mardi', 'hours': '10:00–17:00'},
          ],
        },
      });

      expect(guide.hasAddress, isTrue);
      expect(guide.hasCoordinates, isTrue);
      expect(guide.hasPhone, isTrue);
      expect(guide.hasWebsite, isTrue);
      expect(guide.hasEmail, isTrue);
      expect(guide.hasGallery, isTrue);
      expect(guide.hasAmenities, isTrue);
      expect(guide.hasAccessibility, isTrue);
      expect(guide.hasOpeningHours, isTrue);
      expect(guide.openingHours!.entries.single.dayLabel, 'Mardi');
      expect(guide.openingHours!.note, 'Fermé les jours fériés');
    });

    test('laisse les nouveaux champs vides absents', () {
      final guide = PlaceRecordMapper.tryFromRow(const {
        'slug': 'place-minimal',
        'name': 'Minimal',
        'city_name': 'Rabat',
        'category': 'monument',
        'category_label': 'Monument',
        'neighborhood': 'Centre',
        'price_level': 'Gratuit',
        'summary': 'Résumé',
      });

      expect(guide, isNotNull);
      expect(guide!.hasAddress, isFalse);
      expect(guide.hasCoordinates, isFalse);
      expect(guide.hasContactActions, isFalse);
      expect(guide.hasGallery, isFalse);
      expect(guide.hasOpeningHours, isFalse);
    });
  });
}
