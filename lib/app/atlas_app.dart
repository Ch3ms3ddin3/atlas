import 'package:flutter/material.dart';

import '../design_system/motion/atlas_scroll_behavior.dart';
import '../design_system/theme/atlas_theme.dart';
import '../features/content_reports/data/syncing_content_reports_repository.dart';
import '../features/content_reports/domain/content_reports_repository.dart';
import '../features/content_reports/presentation/content_reports_scope.dart';
import '../features/favorites/data/syncing_favorites_repository.dart';
import '../features/favorites/domain/favorites_repository.dart';
import '../features/favorites/presentation/favorites_scope.dart';
import '../features/onboarding/presentation/startup_gate.dart';

/// Point d'entrée visuel de l'application Atlas.
class AtlasApp extends StatefulWidget {
  const AtlasApp({super.key});

  @override
  State<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends State<AtlasApp> {
  /// Owned above [MaterialApp]'s navigator so modal routes (map preview,
  /// sheets) and pushed pages inherit app scopes — not only the shell page.
  final FavoritesRepository _favoritesRepository = SyncingFavoritesRepository();
  final ContentReportsRepository _contentReportsRepository =
      SyncingContentReportsRepository();

  @override
  void initState() {
    super.initState();
    _favoritesRepository.load();
    _contentReportsRepository.load();
  }

  @override
  void dispose() {
    _favoritesRepository.dispose();
    _contentReportsRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AtlasTheme.light,
      themeMode: ThemeMode.light,
      scrollBehavior: const AtlasScrollBehavior(),
      builder: (context, child) {
        return FavoritesScope(
          repository: _favoritesRepository,
          child: ContentReportsScope(
            repository: _contentReportsRepository,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: StartupGate(
        favoritesRepository: _favoritesRepository,
        contentReportsRepository: _contentReportsRepository,
      ),
    );
  }
}
