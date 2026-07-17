import 'package:flutter/material.dart';

import '../design_system/motion/atlas_scroll_behavior.dart';
import '../design_system/theme/atlas_theme.dart';
import '../features/onboarding/presentation/startup_gate.dart';

/// Point d'entrée visuel de l'application Atlas.
class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: AtlasTheme.light,
      themeMode: ThemeMode.light,
      scrollBehavior: const AtlasScrollBehavior(),
      home: const StartupGate(),
    );
  }
}
