import 'package:flutter/material.dart';

import '../design_system/theme/atlas_theme.dart';
import '../features/shell/presentation/app_shell.dart';

/// Point d'entrée visuel de l'application Atlas.
class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AtlasTheme.light,
      home: const AppShell(),
    );
  }
}
