import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/atlas_colors.dart';
import '../theme/atlas_motion.dart';
import '../theme/atlas_spacing.dart';

/// Image réseau Atlas — cache disque/mémoire, chargement et fallback d'erreur.
///
/// Ne fabrique aucune URL : le caller fournit une URL réelle (ex. Supabase
/// Storage). [errorWidget] / [placeholder] permettent de réutiliser le
/// fallback éditorial lieu (couleur + icône catégorie).
class AtlasNetworkImage extends StatelessWidget {
  const AtlasNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Affiché pendant le chargement — défaut : fond sable stable.
  final Widget? placeholder;

  /// Affiché si l'URL est vide ou si le chargement échoue.
  final Widget? errorWidget;

  /// Décodage mémoire borné (px device) — limite la RAM au scroll.
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// Encode les `(` `)` du chemin — Dart `Uri.toString()` les laisse bruts,
  /// ce qui fait échouer certains chargements image iOS / cache.
  @visibleForTesting
  static String normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.replaceAll('(', '%28').replaceAll(')', '%29');
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(AtlasSpacing.cardRadius);
    final resolvedError = errorWidget ?? const _AtlasNetworkImageDefaultError();
    final resolvedPlaceholder =
        placeholder ?? const _AtlasNetworkImageDefaultLoading();
    final normalized = normalizeUrl(url);

    if (normalized.isEmpty) {
      return ClipRRect(borderRadius: radius, child: resolvedError);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: normalized,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: AtlasMotion.imageFadeDuration,
        fadeOutDuration: AtlasMotion.durationMicro,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (context, _) => resolvedPlaceholder,
        errorWidget: (context, _, _) => resolvedError,
      ),
    );
  }
}

class _AtlasNetworkImageDefaultLoading extends StatelessWidget {
  const _AtlasNetworkImageDefaultLoading();

  @override
  Widget build(BuildContext context) {
    // Fond stable (pas d'animation infinie) — évite les hangs au scroll/tests.
    return const ColoredBox(color: AtlasColors.sandMuted);
  }
}

class _AtlasNetworkImageDefaultError extends StatelessWidget {
  const _AtlasNetworkImageDefaultError();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AtlasColors.sandMuted,
      child: Icon(
        Icons.broken_image_outlined,
        color: AtlasColors.midnightBlueFaint,
      ),
    );
  }
}
