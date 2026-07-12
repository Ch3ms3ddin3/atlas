import 'package:flutter/material.dart';

import 'atlas_colors.dart';

/// Thème Material 3 centralisé pour toute l'application Atlas.
abstract final class AtlasTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AtlasColors.terracotta,
      onPrimary: AtlasColors.warmOffWhite,
      primaryContainer: AtlasColors.terracottaMuted,
      onPrimaryContainer: AtlasColors.midnightBlue,
      secondary: AtlasColors.sand,
      onSecondary: AtlasColors.midnightBlue,
      secondaryContainer: AtlasColors.sandMuted,
      onSecondaryContainer: AtlasColors.midnightBlue,
      tertiary: AtlasColors.subtleGold,
      onTertiary: AtlasColors.midnightBlue,
      tertiaryContainer: Color(0xFFF0E6CE),
      onTertiaryContainer: AtlasColors.midnightBlue,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surface: AtlasColors.warmOffWhite,
      onSurface: AtlasColors.midnightBlue,
      onSurfaceVariant: AtlasColors.midnightBlueMuted,
      outline: AtlasColors.sand,
      outlineVariant: AtlasColors.sandMuted,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AtlasColors.midnightBlue,
      onInverseSurface: AtlasColors.warmOffWhite,
      inversePrimary: AtlasColors.terracottaMuted,
      surfaceTint: AtlasColors.terracotta,
    );

    final textTheme = Typography.material2021().black.apply(
      bodyColor: AtlasColors.midnightBlue,
      displayColor: AtlasColors.midnightBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.warmOffWhite,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.warmOffWhite,
        foregroundColor: AtlasColors.midnightBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AtlasColors.warmOffWhite,
        indicatorColor: AtlasColors.sandMuted,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium;
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(
              color: AtlasColors.terracotta,
              fontWeight: FontWeight.w600,
            );
          }
          return base?.copyWith(color: AtlasColors.midnightBlueMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AtlasColors.terracotta,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AtlasColors.midnightBlueMuted,
            size: 24,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AtlasColors.sandMuted,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AtlasColors.sandMuted),
        ),
      ),
    );
  }
}
