import 'package:flutter/material.dart';

import '../../design_system/theme/atlas_spacing.dart';
import '../../design_system/widgets/atlas_mark.dart';

/// Blocking screen when a release/TestFlight binary lacks real Supabase config.
class AtlasMisconfiguredApp extends StatelessWidget {
  const AtlasMisconfiguredApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AtlasSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AtlasSpacing.xxl),
                    const Center(child: AtlasMark(size: 56)),
                    const SizedBox(height: AtlasSpacing.xl),
                    Text(
                      'Build non configurée',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
