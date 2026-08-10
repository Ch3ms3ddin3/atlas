import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/design_system/widgets/atlas_network_image.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_cover_image.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_detail_hero.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PlaceGuide place({List<String> imageUrls = const []}) {
    return PlaceGuide(
      id: 'place-test',
      name: 'Lieu Test',
      cityName: 'Marrakech',
      category: PlaceCategory.jardin,
      categoryLabel: 'Jardin',
      neighborhood: 'Gueliz',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: const Color(0xFF2D6A4F),
      summary: 'Résumé',
      practicalTips: const [],
      imageUrls: imageUrls,
    );
  }

  test('primaryImageUrl ignore les entrées vides', () {
    final empty = place();
    expect(empty.primaryImageUrl, isNull);
    expect(empty.hasPrimaryImage, isFalse);
    expect(empty.hasGallery, isFalse);

    final blank = place(imageUrls: const ['', '  ']);
    expect(blank.primaryImageUrl, isNull);
    expect(blank.hasGallery, isFalse);

    final withPhoto = place(
      imageUrls: const [
        '',
        ' https://example.supabase.co/storage/v1/object/public/place-photos/a.webp ',
      ],
    );
    expect(
      withPhoto.primaryImageUrl,
      'https://example.supabase.co/storage/v1/object/public/place-photos/a.webp',
    );
    expect(withPhoto.hasPrimaryImage, isTrue);
    expect(withPhoto.hasGallery, isTrue);
  });

  testWidgets('PlaceCoverImage affiche le fallback sans URL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(body: PlaceCoverImage(place: place(), height: 140)),
      ),
    );

    expect(find.byType(PlaceImageFallback), findsOneWidget);
    expect(find.byType(AtlasNetworkImage), findsNothing);
    expect(find.byIcon(Icons.park_outlined), findsOneWidget);
  });

  testWidgets('PlaceCoverImage utilise AtlasNetworkImage avec URL primaire', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: PlaceCoverImage(
            place: place(
              imageUrls: const [
                'https://example.invalid/place-photos/cover.webp',
              ],
            ),
            height: 140,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AtlasNetworkImage), findsOneWidget);
    // Placeholder / erreur = même fallback catégorie (pas d'URL réelle).
    expect(find.byType(PlaceImageFallback), findsWidgets);
    expect(find.byIcon(Icons.park_outlined), findsWidgets);
  });

  testWidgets(
    'cover bundle vérifié gagne sur une URL remote (Jemaa / YSL)',
    (tester) async {
      final jemaa = PlaceGuide(
        id: 'place-jemaa-el-fna',
        name: 'Place Jemaa el-Fna',
        cityName: 'Marrakech',
        category: PlaceCategory.souk,
        categoryLabel: 'Souk',
        neighborhood: 'Médina',
        priceLevel: '€',
        isEditorsPick: true,
        imageColor: const Color(0xFF8B4513),
        summary: 'Résumé',
        practicalTips: const [],
        imageUrls: const [
          'https://example.invalid/place-photos/old-jemaa.webp',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(
            body: PlaceCoverImage(place: jemaa, height: 140),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(AtlasNetworkImage), findsNothing);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/explorer_place_covers/place-photos/place-jemaa-el-fna/cover.webp',
      );
    },
  );

  test('AtlasNetworkImage.encode les parenthèses du chemin Storage', () {
    const raw =
        'https://djuomszcdjuwikfdfcju.supabase.co/storage/v1/object/public/place-photos/place-majorelle/Blue_and_more_(11277856173).jpg';
    expect(
      AtlasNetworkImage.normalizeUrl(raw),
      'https://djuomszcdjuwikfdfcju.supabase.co/storage/v1/object/public/place-photos/place-majorelle/Blue_and_more_%2811277856173%29.jpg',
    );
  });

  testWidgets('AtlasNetworkImage URL vide affiche errorWidget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 100,
            width: 100,
            child: AtlasNetworkImage(
              url: '   ',
              errorWidget: ColoredBox(
                color: Colors.red,
                child: Text('fallback'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('fallback'), findsOneWidget);
  });

  testWidgets('PlaceDetailHero réutilise PlaceCoverImage', (tester) async {
    final favorites = LocalFavoritesRepository();
    await favorites.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: FavoritesScope(
          repository: favorites,
          child: Scaffold(
            body: PlaceDetailHero(place: place(), onReport: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PlaceCoverImage), findsOneWidget);
    expect(find.byType(PlaceImageFallback), findsOneWidget);
    expect(find.text('Lieu Test'), findsOneWidget);
    expect(find.text('Gueliz · Marrakech'), findsOneWidget);
    expect(find.byTooltip('Signaler un problème'), findsOneWidget);
  });
}
