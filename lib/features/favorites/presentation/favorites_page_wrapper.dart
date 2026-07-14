import 'package:flutter/material.dart';

import 'favorites_scope.dart';

/// Réinjecte [FavoritesScope] sur une route poussée hors de l'arbre du shell.
Widget wrapWithFavoritesScope(BuildContext context, Widget child) {
  return FavoritesScope(
    repository: FavoritesScope.read(context),
    child: child,
  );
}
