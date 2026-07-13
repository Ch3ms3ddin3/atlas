import 'package:flutter/material.dart';

import 'atlas_colors.dart';
import 'atlas_spacing.dart';
import 'atlas_typography.dart';

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
      tertiaryContainer: AtlasColors.subtleGoldMuted,
      onTertiaryContainer: AtlasColors.midnightBlue,
      error: AtlasColors.error,
      onError: AtlasColors.surfaceWhite,
      errorContainer: AtlasColors.errorMuted,
      onErrorContainer: AtlasColors.errorOnContainer,
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

    final textTheme = AtlasTypography.textTheme();

    const fieldBorderRadius = BorderRadius.all(Radius.circular(12));
    final inputBorder = OutlineInputBorder(
      borderRadius: fieldBorderRadius,
      borderSide: const BorderSide(color: AtlasColors.sandMuted),
    );
    final focusedInputBorder = OutlineInputBorder(
      borderRadius: fieldBorderRadius,
      borderSide: const BorderSide(color: AtlasColors.terracotta, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.warmOffWhite,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AtlasColors.warmOffWhite,
        foregroundColor: AtlasColors.midnightBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
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
        color: AtlasColors.surfaceWhite,
        elevation: 0,
        shadowColor: const Color(0x1A1A2332),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
          side: BorderSide(
            color: AtlasColors.sandMuted.withValues(alpha: 0.65),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.surfaceWhite,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.md,
          vertical: AtlasSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusedInputBorder,
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AtlasColors.error),
        ),
        focusedErrorBorder: focusedInputBorder.copyWith(
          borderSide: const BorderSide(color: AtlasColors.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AtlasColors.midnightBlueMuted.withValues(alpha: 0.68),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: AtlasColors.warmOffWhite,
        selectedColor: AtlasColors.terracottaMuted,
        side: const BorderSide(color: AtlasColors.sandMuted),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AtlasColors.midnightBlueMuted,
          fontWeight: FontWeight.w400,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AtlasColors.midnightBlue,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.sm,
          vertical: AtlasSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AtlasColors.terracotta.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.pressed)) {
              return AtlasColors.terracottaDeep;
            }
            return AtlasColors.terracotta;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AtlasColors.warmOffWhite.withValues(alpha: 0.7);
            }
            return AtlasColors.warmOffWhite;
          }),
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AtlasSpacing.xl,
              vertical: AtlasSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AtlasColors.terracotta,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AtlasColors.midnightBlue,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AtlasColors.warmOffWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
